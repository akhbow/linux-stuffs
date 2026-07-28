# Task: Migrate "Works - UNDA" off the FUSE mount to a real local folder

You are running on the PC. This machine has the same rclone/systemd-user Google
Drive setup as the user's laptop (remote name `gdrive`, mount at `~/GoogleDrive`
via `rclone-mount.service`, bisync via `gdrive-do-sync.sh` on a timer). The
laptop was already migrated on 2026-07-03; this document tells you how to do
the same thing here. Do not ask the user to re-explain the setup — verify it
yourself with the commands in Step 0, then proceed.

## Why

`~/GoogleDrive` is a FUSE mount (`rclone mount`), not real local storage.
Files are fetched on demand and cached under `--vfs-cache-mode full` with a
5 GB cache cap. If `Works - UNDA` is larger than 5 GB, files that fall out of
cache get re-fetched over the network on open — that's a real, user-visible
delay, not a perception issue. The fix is to give `Works - UNDA` a real
directory on disk, outside the FUSE mount, and point the existing bisync at
that instead. Nothing else about the mount or the rest of Drive changes.

## Hard constraints — do not violate

- Never change the rclone remote name. It must stay exactly `gdrive` — both
  `gdrive-do-sync.sh` and `gdrive-refresh.sh` hardcode it.
- Do not touch `gdrive-refresh.sh` or `rclone-mount.service` — they manage the
  FUSE mount for the rest of Drive and are unaffected by this change.
- Do not skip the `--resync` step (Step 5) — it is required the first time
  bisync runs against a new local↔remote path pairing, per this project's
  known rclone constraints.
- Do not delete anything on the `gdrive:` remote at any point. Every step here
  only creates/reads local files or reconfigures local scripts/services.

## Step 0 — Verify assumptions before changing anything

Run these and actually read the output; don't assume they match the laptop.

```bash
rclone listremotes                                   # must include "gdrive:"
systemctl --user list-timers | grep gdrive           # confirm gdrive-sync.timer exists
cat ~/gdrive-do-sync.sh                               # find current LOCAL= path
cat ~/.config/systemd/user/gdrive-sync.service        # check for After=/Requires= rclone-mount.service
rclone size gdrive:"Works - UNDA"                     # actual size/object count on this account
df -h ~                                               # confirm enough free disk space for that size
```

If `gdrive-sync.timer` doesn't exist on this machine, stop and tell the user —
the sync topology here differs from the laptop and this runbook's steps 1/7
won't apply as written.

## Step 1 — Pause the sync timer

```bash
systemctl --user stop gdrive-sync.timer
```

## Step 2 — Create the real local folder

Sibling to `~/GoogleDrive`, not inside it.

```bash
mkdir -p ~/"Works - UNDA"
```

## Step 3 — Seed it with a full copy from Drive

This is a one-time download. Run it in the background and poll it — do not
block synchronously, it can take a long time.

```bash
rclone copy gdrive:"Works - UNDA" ~/"Works - UNDA" \
    --progress --stats-one-line --stats 10s
```

**Expect the progress output to look broken. It isn't.** Throughput will
swing wildly (multi-MiB/s down to tens of KiB/s) and the ETA will bounce
between minutes and multiple days. This is normal — Drive charges a per-file
API round-trip, and most files are small, so file *count* drives duration far
more than total bytes. On the laptop, 14.4 GB across 4,064 files took ~2
hours.

Before concluding it's throttled, check for a real error, not noise:

```bash
grep -o "userRateLimitExceeded" /path/to/copy.log
```

A raw grep for `403` or `rate limit` will false-positive on ordinary numbers
in the progress stream (e.g. "5.403 MiB/s"). Only `userRateLimitExceeded` or an
explicit `ERROR` line from rclone means something is actually wrong.

When it finishes, confirm before moving on:

```bash
du -sh ~/"Works - UNDA"
find ~/"Works - UNDA" -type f | wc -l
```

Compare against the `rclone size` output from Step 0 — file count and rough
size should match.

## Step 4 — Repoint the sync script

Edit `~/gdrive-do-sync.sh`. Change only the `LOCAL` line — leave the remote,
excludes, and flags untouched:

```bash
# before
LOCAL="/home/<user>/GoogleDrive/Works - UNDA"
# after
LOCAL="/home/<user>/Works - UNDA"
```

Use `$HOME` resolved to the actual path on this machine, not a literal copy of
the laptop's username.

## Step 5 — Decouple the sync service from the mount

Edit `~/.config/systemd/user/gdrive-sync.service`. Remove the mount
dependency — the real folder doesn't need the FUSE mount to exist:

```ini
[Unit]
Description=Rclone Google Drive Bisync (Works - UNDA)
# delete these two lines if present:
# After=rclone-mount.service
# Requires=rclone-mount.service

[Service]
Type=oneshot
ExecStart=/home/<user>/gdrive-do-sync.sh
```

If this machine's service file doesn't have those lines, there's nothing to
remove — move on.

## Step 6 — Establish a fresh bisync baseline

Run this by hand (not via the timer) so you can watch it succeed. Substitute
the real local path from Step 2.

```bash
rclone bisync "/home/<user>/Works - UNDA" gdrive:"Works - UNDA" \
    --resync --resilient --remove-empty-dirs \
    --exclude "**/.~lock.*#" \
    --log-file /tmp/rclone-bisync.log --log-level INFO
```

Tail the log until it ends in `Bisync successful`. Expect "nothing to
transfer" in both directions, since Step 3 already seeded an exact copy. If it
reports actual transfers or errors, stop and investigate before proceeding —
do not restart the timer on top of a failed resync.

## Step 7 — Reload and resume

```bash
systemctl --user daemon-reload
systemctl --user start gdrive-sync.timer
```

The timer's `OnActiveSec=1min` (check the actual value in
`gdrive-sync.timer` on this machine) means a real sync cycle fires almost
immediately after this — that's expected. Wait for it, then re-check
`/tmp/rclone-bisync.log` for a second clean `Bisync successful` (or "No
changes found") to confirm the *ongoing*, non-resync sync path works.

## Verification checklist

- [ ] `ls -la ~/"Works - UNDA"` — real files, non-zero sizes.
- [ ] `du -sh ~/"Works - UNDA"` — matches the remote size from Step 0.
- [ ] Opening a file is instant — no fetch delay.
- [ ] `systemctl --user status rclone-mount.service gdrive-sync.timer gdrive-sync.service` — mount still healthy, timer active, last run clean.
- [ ] `/tmp/rclone-bisync.log` ends in `Bisync successful`, no errors, for both the resync run and the first automatic timer cycle.
- [ ] `~/GoogleDrive/Works - UNDA` (the old FUSE-mounted path) still shows the same content — this is expected and harmless, it's just another view into the same Drive folder. Actual work should now happen in `~/Works - UNDA`.

## If something goes wrong

Drive is never modified destructively by any step above — it stays the source
of truth throughout, so rollback is local-only:

1. Revert the `LOCAL=` line in `gdrive-do-sync.sh` and restore the
   `After=`/`Requires=` lines in `gdrive-sync.service` (from Step 0's captured
   `cat` output).
2. `systemctl --user daemon-reload && systemctl --user start gdrive-sync.timer`
   to resume the original FUSE-backed sync.
3. Delete `~/"Works - UNDA"` freely — it's a copy, not the source.

## When done

Report back: final file count and size in `~/"Works - UNDA"`, confirmation the
timer is active with a clean last run, and anything that differed from this
runbook (e.g. a different timer interval, a missing `Requires=` line, a
different remote folder size) so the record stays accurate for next time.
