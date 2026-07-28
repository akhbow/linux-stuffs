# Google Drive rclone Sync — Setup Report

**Purpose:** This session brought the `gdrive` rclone bisync project (defined in `~/CLAUDE.md`) up from scratch on this laptop (Fedora 44), after a full OS wipe had erased the previous `rclone.conf`. This report exists so the same setup can be replicated cleanly on a new PC without re-discovering the same gotchas.

**Session date:** 2026-07-03

---

## 1. Architecture

Four systemd **user** units + two scripts, all built around one rclone remote named `gdrive`:

| Component | What it does |
|---|---|
| `~/.config/rclone/rclone.conf` (`[gdrive]`, type `drive`) | OAuth-authenticated connection to Google Drive |
| `rclone-mount.service` | FUSE-mounts the whole `gdrive:` remote live at `~/GoogleDrive` |
| `~/gdrive-refresh.sh` | (Re)writes `rclone-mount.service`, clears VFS cache, restarts the mount |
| `~/gdrive-do-sync.sh` | Runs `rclone bisync` between `~/GoogleDrive/Works - UNDA` (the mounted path) and `gdrive:Works - UNDA` |
| `gdrive-sync.service` + `gdrive-sync.timer` | **New this session** — runs `gdrive-do-sync.sh` automatically every ~8 minutes |

Note the sync is bisyncing a path that is *itself* the live FUSE mount, not a separate offline copy — so the mount already gives near-live read/write access to Drive; the periodic bisync is a reconciliation safety net (catches deletes/renames, cache edge cases), not what makes changes "show up."

## 2. Bugs found and fixed this session

These were latent bugs in the existing scripts/config, invisible until an actual fresh bring-up was attempted. **Check for the same issues if these scripts are copied to the new PC as-is:**

1. **OAuth token missing.** `rclone.conf` had only `[gdrive]` / `type = drive` — no token. The remote had been created but OAuth was never completed. Fixed by running `rclone config reconnect gdrive:` interactively (opens `http://127.0.0.1:53682/auth?state=...` — must be opened in a browser **on the same machine**, since it's a localhost redirect).
   - **Gotcha:** don't auto-answer the reconnect wizard's prompts (e.g. piping `yes y`). One of its questions is *"Configure this as a Shared Drive (Team Drive)?"* — answering `y` blindly here set `team_drive = y` (a literal garbage value) in the config, which broke `rclone lsd` with `Shared drive not found: y`. Fixed by deleting the `team_drive` and `root_folder_id` lines from `rclone.conf`. **On the new PC: run the reconnect command yourself, by hand, and answer `n` to the Team Drive prompt** (this is a personal "My Drive" folder, not a Shared Drive).

2. **Wrong hardcoded username.** `gdrive-do-sync.sh` had `LOCAL="$HOME/GoogleDrive/Works - UNDA"` — a leftover from a different machine/user. Fixed to `$HOME/GoogleDrive/Works - UNDA`. **On the new PC, this line must be updated again to match that machine's actual `$HOME`.**

3. **`fusermount` vs `fusermount3`.** `gdrive-refresh.sh` used plain `fusermount` (fuse2) in two places — the systemd unit's `ExecStop=` line and the force-unmount step (`fusermount -uz`). Fedora 44 defaults to fuse3, so both were changed to `fusermount3`. **On the new PC: confirm which binary actually exists (`which fusermount3`) before assuming — this depends on the distro/fuse version, not just "Fedora 44" being the target.**

4. **Mount point directory doesn't auto-create.** `rclone mount` requires `~/GoogleDrive` to already exist — it does not create it. Without it, `rclone-mount.service` fails immediately with `cannot open: ... no such file or directory` and systemd restart-loops into `Start request repeated too quickly`. Fix: `mkdir -p ~/GoogleDrive` **before** first starting the service. Neither script currently does this automatically — worth adding a `mkdir -p %h/GoogleDrive` line to `gdrive-refresh.sh` if replicating.

## 3. New: periodic sync timer

Added because the sync previously only ran when manually invoked.

**Files created:**
- `~/.config/systemd/user/gdrive-sync.service`:
  ```ini
  [Unit]
  Description=Rclone Google Drive Bisync (Works - UNDA)
  After=rclone-mount.service
  Requires=rclone-mount.service

  [Service]
  Type=oneshot
  ExecStart=$HOME/gdrive-do-sync.sh
  ```
- `~/.config/systemd/user/gdrive-sync.timer` (final working version):
  ```ini
  [Unit]
  Description=Run Rclone Google Drive Bisync every 8 minutes

  [Timer]
  OnActiveSec=1min
  OnUnitActiveSec=8min

  [Install]
  WantedBy=timers.target
  ```
- Enabled with: `systemctl --user daemon-reload && systemctl --user enable --now gdrive-sync.timer`

**Gotcha — do not use `OnCalendar=*:0/8` for this.** It was tried first and is wrong for any run duration close to the interval:
- `*:0/8` is a wall-clock grid (`:00,:08,:16,...,:56`) that **resets every hour**, so the gap from `:56` to the next hour's `:00` is only **4 minutes**, not 8.
- This dataset's bisync run takes ~5–6 minutes (currently ~20k+ files/folders listed under "Works - UNDA"), longer than that 4-minute gap.
- Result: the tick landed while the previous run was still active. Systemd doesn't drop a missed calendar tick — it queues it and fires the instant the unit goes idle, producing an unwanted **back-to-back run with zero idle gap**, observed directly in this session (a run finished and a new one started in the same second).

**Fix used instead:** `OnActiveSec` + `OnUnitActiveSec` — a *relative* timer that schedules the next run N minutes after each run's own start, independent of wall-clock hour boundaries. This keeps consistent spacing regardless of run duration (as long as runs finish faster than the interval) and has no hour-boundary edge case. **Use this pattern on the new PC too — don't reach for `OnCalendar` unless the sync is near-instant.**

## 4. Step-by-step replication on the new PC

1. Install `rclone` and confirm fuse3 tooling (`which fusermount3`).
2. Copy `gdrive-do-sync.sh` and `gdrive-refresh.sh` over. **Edit `LOCAL=` in `gdrive-do-sync.sh`** to match the new machine's actual `/home/<user>/GoogleDrive/Works - UNDA`. If the new PC isn't Fedora/fuse3, double check the `fusermount3` calls in `gdrive-refresh.sh` are still correct for that system.
3. Create the `gdrive` remote (name must stay exactly `gdrive` — both scripts hardcode it) and complete OAuth **yourself, interactively**:
   ```
   rclone config create gdrive drive   # or: rclone config
   rclone config reconnect gdrive:
   ```
   Open the printed `http://127.0.0.1:53682/...` link in a browser on that same machine. Answer **No** to any "Shared/Team Drive" prompt unless intentionally using one.
4. `mkdir -p ~/GoogleDrive` (must pre-exist before the mount service starts).
5. Run `~/gdrive-refresh.sh` to write and start `rclone-mount.service`.
6. Verify the mount: `systemctl --user status rclone-mount.service`, `rclone lsd gdrive:`, `ls ~/GoogleDrive`.
7. **First-ever bisync on a new machine needs `--resync`** to establish the baseline — run manually once with the same flags as in `gdrive-do-sync.sh` plus `--resync`, then confirm `ls ~/GoogleDrive/"Works - UNDA"` and `/tmp/rclone-bisync.log` show `Bisync successful`.
8. Set up `gdrive-sync.service` + `gdrive-sync.timer` as in section 3 above (using the relative-timer pattern, not `OnCalendar`).
9. `systemctl --user daemon-reload && systemctl --user enable --now gdrive-sync.timer`.

## 5. Verification checklist (also matches CLAUDE.md's standing instruction)

- `systemctl --user status rclone-mount.service` → `active (running)`, same PID persists (no restart loop)
- `rclone lsd gdrive:` → lists folders without error
- `ls ~/GoogleDrive/"Works - UNDA"` → shows files
- `systemctl --user list-timers` → `gdrive-sync.timer` shows a sane next-fire time, spaced correctly from the last trigger
- `journalctl --user -u gdrive-sync.service` → each run shows `Starting` → `Finished` with no overlapping `Starting` lines while a previous run is still active
- `tail /tmp/rclone-bisync.log` → ends in `Bisync successful`

## 6. Current live config (as of 2026-07-14, laptop + PC)

- Remote: `gdrive` (type `drive`, personal My Drive — no `team_drive` set)
- Mount: `~/GoogleDrive`, via `rclone-mount.service` — intentionally `inactive`/`disabled` on **both** machines since the `Works - UNDA` migration off the mount (see `gdrive-works-unda-migration.md`); confirmed on the PC 2026-07-14 (`~/GoogleDrive` empty, `Works - UNDA` not reachable through it, `rclone lsd gdrive:` still works fine directly against the remote)
- Synced folder: `Works - UNDA`
- Sync cadence: every ~8 minutes via `gdrive-sync.timer` (relative timer)
- Bisync flags: `--exclude "**/.~lock.*#" --resilient --max-lock 15m --remove-empty-dirs --conflict-resolve newer --conflict-loser num` (`--max-lock 15m` added 2026-07-14, see §7)
- `loginctl enable-linger <user>`: enabled on both machines 2026-07-14 (see §7)
- Log: `/tmp/rclone-bisync.log`

## 7. Incident 2026-07-14: stale bisync lock silently blocked all sync for ~12 hours

**Symptom:** changes under `Works - UNDA` (noticed via the `RESEARCH IDEAS` folder specifically) stopped propagating to Drive and to the other machine. Traced via `/tmp/rclone-bisync.log` and `journalctl --user -u gdrive-sync.service`.

**Root cause — two compounding gaps in the original setup:**
1. `gdrive-do-sync.sh` never passed `--max-lock` to `rclone bisync`. rclone's default for that flag is `0`, meaning lock files **never auto-expire**. The log's "Expires at 2226-05-26" isn't a bug — it's rclone's literal encoding of "never," which was easy to misread as a malfunction.
2. On the laptop, a bisync run in progress was killed by **SIGTERM** when the user logged out of the KDE session (`journalctl` showed `org.kde.LogoutPrompt` → `org.kde.Shutdown` → the running `gdrive-sync.service` killed with `code=killed, status=15/TERM`, 8 minutes into that run). Root enabler: `loginctl show-user <user> -p Linger` was `Linger=no`, so systemd tears down the entire `--user` instance — and every unit in it — on logout instead of letting background units finish. The killed rclone process never got a chance to delete its own `.lck` file.

Once orphaned, the lock never expired (gap 1) and blocked every subsequent timer tick — across a reboot, ~12 hours, dozens of ticks — with `prior lock file found`, until it was found and deleted by hand.

**Fix (applied to both laptop and PC, 2026-07-14):**
- Added `--max-lock 15m` to `gdrive-do-sync.sh` on both machines (well above the normal ~5–12 min run time for this dataset). A lock older than that is now treated as expired automatically, so a killed/crashed run self-heals on the next timer tick — no more manual `rclone deletefile`.
- `loginctl enable-linger <user>` on both machines, so the user's systemd `--user` instance now survives logout/session-end and an in-flight bisync is no longer killed mid-run by a desktop logout.

**Verification:** manual `~/gdrive-do-sync.sh` runs on both machines completed with `Sinkronisasi selesai dengan sukses`; the lock file's `TimeExpires` now shows a realistic ~15-minute window (confirmed via `lock file renewed for 15m0s` in the log) instead of the year 2226.

**If this recurs anyway:** `cat ~/.cache/rclone/bisync/*.lck` — if `TimeExpires` is unreasonably far out and `ps -p <the PID field>` shows nothing, it's a stale lock from before this fix (or from a machine that hasn't gotten it yet); `rclone deletefile` the `.lck` path printed in the bisync error, then re-run. Should no longer occur going forward given `--max-lock`.

## 8. Incident 2026-07-28: bisync baseline listings lost → every run aborts error 7

**Symptom:** `gdrive-sync.timer` fires every 8 min but every run fails with exit code 7; `tail /tmp/rclone-bisync.log` shows `Bisync critical error: cannot find prior Path1 or Path2 listings, likely due to critical error on prior run` repeatedly (started 2026-07-25 16:49, hundreds of failed ticks).

**Root cause:** the active baseline listing files `~/.cache/rclone/bisync/*..gdrive_Works_-_UNDA.path1.lst` and `.path2.lst` were gone — only `*.lst-old` (last good, 09:07) and `*.lst-err` (failed run, 09:16) remained. A prior run had entered the critical-error state (left a `-err` listing) and the active baseline never completed, so rclone refused to proceed. Because the script uses `--resilient`, the error is *retryable only with `--resync`* — the automatic timer ticks can never self-heal it, so it loops forever.

**Why `--resilient` doesn't save you here:** `--resilient` masks *transient* per-file errors and lets a run finish, but a missing/corrupt baseline is a fatal structural error it deliberately will not auto-recover from. That's by design — an automatic resync on a missing baseline could mass-delete if the two sides had diverged.

**Fix (recovery, NOT a code change):** stop the timer, run a one-shot `--resync` with the same flags as `gdrive-do-sync.sh`, confirm `Bisync successful`, then resume the timer and verify the next automatic tick ends clean (`No changes found` / `Bisync successful`). Exact command:
```bash
systemctl --user stop gdrive-sync.timer
/usr/bin/rclone bisync "/home/<user>/Works - UNDA" gdrive:"Works - UNDA" \
    --resync --resilient --max-lock 15m --remove-empty-dirs \
    --exclude "**/.~lock.*#" --conflict-resolve newer --conflict-loser num \
    --log-file /tmp/rclone-bisync.log --log-level INFO
# confirm "Bisync successful" in the log, then:
systemctl --user start gdrive-sync.timer
```
Observed result this incident: `Bisync successful` in 5m18s (only 3 files / 15 KiB transferred — sides were already nearly identical), baseline `*.path1.lst`/`*.path2.lst` recreated (595.075 B), first post-resync automatic tick → `No changes found`. Fully recovered.

**Divergence check before resync (read-only, safe):** `du -sh ~/Works\ -\ UNDA` + `find … -type f | wc -l` vs `rclone size gdrive:"Works - UNDA"`. This incident showed local 4.193 files / 15,0 GiB vs remote 4.201 objects / 14,8 GiB — the ~8-object gap is Google-native Docs/Sheets (Drive reports them as "unknown size"), not missing data. `--resync` with `--conflict-resolve newer` keeps the newest version of any real conflict; it does not mass-delete on its own.

**Prevention:** no code-level prevention identified — a missing baseline is a legitimate "ask the human" condition by rclone design. The actionable safeguard is **early detection**: a timer that has been erroring for >1 cycle is stuck, not recovering. A cheap watchdog (e.g. grep the last bisync log line for `Bisync successful`/`No changes found`; if absent across N consecutive ticks, alert) would catch this before it sits for 3 days. **Implemented 2026-07-28 — see §9.**

## 9. Watchdog — early detection of stuck bisync (added 2026-07-28)

Detects the §8 condition automatically so it can't sit for 3 days unnoticed. **Detection + alert only — it does NOT auto-recover** (auto-resync on a missing baseline is unsafe; recovery stays manual per §8).

**Files:**
- `~/gdrive-bisync-watchdog.sh` — reads the last bisync result line from `/tmp/rclone-bisync.log`, counts consecutive failures, alerts at threshold.
- `~/.config/systemd/user/gdrive-bisync-watchdog.service` — oneshot, runs the script.
- `~/.config/systemd/user/gdrive-bisync-watchdog.timer` — fires every 10 min (`OnActiveSec=1min`, `OnUnitActiveSec=10min`, relative timer like the sync timer — avoids hour-boundary edge case from §3).

**Behavior:**
- Threshold = **3 consecutive failed runs** → alert (≈30 min vs the 3 days it sat in §8).
- Alert channel: desktop `notify-send -u critical` + append to `~/.cache/rclone/bisync-watchdog.log` + drops marker file `~/.cache/rclone/bisync-watchdog.ALERT`.
- A clean run (`Bisync successful` / `No changes found`) resets the counter to 0 and clears the alert marker.
- State persisted in `~/.cache/rclone/bisync-watchdog.state` (`COUNTER`, `ALERTED`) so it survives across timer ticks/reboots.

**Enable:**
```bash
chmod +x ~/gdrive-bisync-watchdog.sh
systemctl --user daemon-reload
systemctl --user enable --now gdrive-bisync-watchdog.timer
```

**Verify:** `systemctl --user status gdrive-bisync-watchdog.timer` → active. Logic test (sandbox, 3 fake failures → alert at 3rd; clean run → reset) passed 2026-07-28.

**If you get the alert:** do NOT let the watchdog fix it. Follow §8 recovery (`--resync` manually, confirm `Bisync successful`, resume `gdrive-sync.timer`). When the next clean bisync run lands, the watchdog auto-clears.
