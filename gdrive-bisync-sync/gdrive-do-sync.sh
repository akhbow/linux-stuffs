#!/bin/bash

# ============================================================
#  gdrive-do-sync.sh — Two-way Google Drive sync
#  Uses rclone bisync so deletions are respected on both
#  sides (local & cloud).
# ============================================================

set -u

LOCAL="$HOME/Works - UNDA"
REMOTE='gdrive:"Works - UNDA"'
LOG="/tmp/rclone-bisync.log"
EXCLUDE="**/.~lock.*#"
LOCK_DIR="$HOME/.cache/rclone/bisync"
LOCK_FILE="$LOCK_DIR/works-unda-bisync.lck"

# --- Anti-overlap guard -------------------------------------------------
# If another run is still active (lock file exists & valid), skip with
# exit 0. The timer fires every 8 minutes while a run takes ~3-8 minutes.
# Without the guard, a new run would overwrite the old lock → bisync
# aborts and wastes quota.
if [ -f "$LOCK_FILE" ]; then
    # Check whether the process that made the lock is still alive
    LOCK_PID=$(fuser "$LOCK_FILE" 2>/dev/null | head -1)
    if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Previous run still active (PID $LOCK_PID). Skipping."
        exit 0
    fi
    # Lock exists but process is dead → stale lock, clean it up
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Stale lock detected. Cleaning up..."
    rm -f "$LOCK_FILE"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting bisync sync..."

/usr/bin/rclone bisync \
    "$LOCAL" \
    gdrive:"Works - UNDA" \
    --exclude "$EXCLUDE" \
    --resilient \
    --max-lock 30m \
    --remove-empty-dirs \
    --conflict-resolve newer \
    --conflict-loser num \
    --transfers 4 \
    --tpslimit 8 \
    --log-file "$LOG" \
    --log-level INFO

STATUS=$?

if [ $STATUS -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sync completed successfully."
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: Sync finished with error (code: $STATUS)."
    echo "Check log at: $LOG"
fi

exit $STATUS
