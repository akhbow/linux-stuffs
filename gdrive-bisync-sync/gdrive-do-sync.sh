#!/bin/bash

# ============================================================
#  gdrive-do-sync.sh — Sinkronisasi Dua Arah Google Drive
#  Menggunakan rclone bisync agar penghapusan file dihormati
#  di kedua sisi (lokal & cloud).
# ============================================================

LOCAL="$HOME/Works - UNDA"
REMOTE='gdrive:"Works - UNDA"'
LOG="/tmp/rclone-bisync.log"
EXCLUDE="**/.~lock.*#"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Memulai sinkronisasi bisync..."

/usr/bin/rclone bisync \
    "$LOCAL" \
    gdrive:"Works - UNDA" \
    --exclude "$EXCLUDE" \
    --resilient \
    --max-lock 15m \
    --remove-empty-dirs \
    --conflict-resolve newer \
    --conflict-loser num \
    --log-file "$LOG" \
    --log-level INFO

STATUS=$?

if [ $STATUS -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sinkronisasi selesai dengan sukses."
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] PERINGATAN: Sinkronisasi selesai dengan error (kode: $STATUS)."
    echo "Periksa log di: $LOG"
fi
