# gdrive-bisync-sync

Two-way (bidirectional) sync between a Google Drive folder (`Works - UNDA`) and a
local directory, kept healthy with a self-healing systemd timer + a watchdog that
flags a stuck sync early.

Built and tested on Fedora 44 (fuse3 / `fusermount3`), rclone v1.74.x.

> **Scope note:** Google Drive credentials live in `~/.config/rclone/rclone.conf`
> (created locally via `rclone config` / `rclone config reconnect`). **That file is
> intentionally NOT in this repo** — you create it yourself (see Setup). Nothing in
> this repo contains tokens, client secrets, or passwords.

## What's in here

| Path | What |
|---|---|
| `gdrive-do-sync.sh` | Runs `rclone bisync` (the actual two-way sync). |
| `gdrive-refresh.sh` | Rewrites `rclone-mount.service`, clears VFS cache, restarts the mount. |
| `gdrive-bisync-watchdog.sh` | Early-detection watchdog — alerts if the sync fails N times in a row. Does **not** auto-fix. |
| `systemd/` | The five systemd **user** units (`.service` / `.timer`) to drop into `~/.config/systemd/user/`. |
| `docs/gdrive-setup-report.md` | Full setup report + incident log (incl. the recovery runbook). |
| `docs/gdrive-works-unda-migration.md` | Runbook for migrating the synced folder off the FUSE mount to a real local dir. |

## Architecture in one paragraph

`rclone-mount.service` FUSE-mounts the whole `gdrive:` remote at `~/GoogleDrive`
(optional — handy for browsing the rest of Drive). `gdrive-sync.timer` fires
`gdrive-do-sync.sh` every 8 minutes; that script runs `rclone bisync` between a real
local folder (`~/Works - UNDA`) and `gdrive:Works - UNDA` so that deletes/renames on
either side are reconciled. `gdrive-bisync-watchdog.timer` runs every 10 minutes and
reads the last bisync result; after 3 consecutive failures it raises a desktop alert
so a missing-baseline situation (which needs a manual `--resync`) is caught in ~30 min
instead of days.

## Setup

1. Install rclone, and confirm fuse3 tooling: `which fusermount3`.
2. Create the `gdrive` remote (name must stay exactly `gdrive` — the scripts hardcode
   it) and complete OAuth **yourself, interactively**:
   ```bash
   rclone config create gdrive drive
   rclone config reconnect gdrive:
   ```
   Open the printed `http://127.0.0.1:53682/...` link in a browser **on this machine**.
   Answer **No** to any "Shared/Team Drive" prompt (personal My Drive).
3. `mkdir -p ~/GoogleDrive` (must exist before the mount service starts).
4. Copy the scripts next to your home and the units into the systemd user dir:
   ```bash
   cp gdrive-do-sync.sh gdrive-refresh.sh gdrive-bisync-watchdog.sh ~/
   chmod +x ~/gdrive-*.sh
   mkdir -p ~/.config/systemd/user
   cp systemd/* ~/.config/systemd/user/
   ```
5. Edit `LOCAL=` in `gdrive-do-sync.sh` to match this machine's real home
   (the repo copy uses `$HOME`; your deployed copy should resolve it, e.g.
   `LOCAL="$HOME/Works - UNDA"`).
6. (Optional) start the mount: `~/gdrive-refresh.sh`.
7. Enable the sync + watchdog timers:
   ```bash
   systemctl --user daemon-reload
   systemctl --user enable --now gdrive-sync.timer
   systemctl --user enable --now gdrive-bisync-watchdog.timer
   ```
8. **First-ever bisync on a machine needs `--resync`** to establish the baseline:
   ```bash
   rclone bisync "$HOME/Works - UNDA" gdrive:"Works - UNDA" \
       --resync --resilient --max-lock 15m --remove-empty-dirs \
       --exclude "**/.~lock.*#" --conflict-resolve newer --conflict-loser num \
       --log-file /tmp/rclone-bisync.log --log-level INFO
   ```
   Confirm `Bisync successful` in `/tmp/rclone-bisync.log`.

## Recovery (if the watchdog alerts "GDrive bisync STUCK")

A stuck sync is almost always a **missing bisync baseline** (rclone refuses to proceed
without prior listings). Recovery is manual by design — an automatic resync on a missing
baseline could mass-delete if the two sides had diverged:

```bash
systemctl --user stop gdrive-sync.timer
rclone bisync "$HOME/Works - UNDA" gdrive:"Works - UNDA" \
    --resync --resilient --max-lock 15m --remove-empty-dirs \
    --exclude "**/.~lock.*#" --conflict-resolve newer --conflict-loser num \
    --log-file /tmp/rclone-bisync.log --log-level INFO
# confirm "Bisync successful", then:
systemctl --user start gdrive-sync.timer
```

The watchdog auto-clears its alert once a clean run lands. Full detail in
`docs/gdrive-setup-report.md` (§7–§9).

## Notes / gotchas

- **Relative timer, not `OnCalendar`.** The sync uses `OnActiveSec` + `OnUnitActiveSec`
  (not `*:0/8`) so runs stay evenly spaced regardless of run duration — `OnCalendar`
  resets every hour and can fire a tick while the previous run is still active.
- **`--max-lock 15m`** makes a killed/crashed bisync self-heal on the next tick (a lock
  older than 15 min is treated as expired). Without it, a lock never expires and blocks
  all future sync until deleted by hand.
- **`loginctl enable-linger <user>`** so the user systemd instance survives logout and an
  in-flight bisync isn't killed mid-run by a desktop session end.
- Google-native Docs/Sheets appear as "unknown size" in `rclone size` and won't have a
  real file on disk — that's expected, not missing data.
