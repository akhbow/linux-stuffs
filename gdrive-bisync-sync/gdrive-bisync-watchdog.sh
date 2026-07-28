#!/bin/bash
# ============================================================
#  gdrive-bisync-watchdog.sh — Deteksi dini bisync macet
#  Dijalankan tiap N menit oleh gdrive-bisync-watchdog.timer.
#  Membaca hasil run terakhir di /tmp/rclone-bisync.log. Jika
#  THRESHOLD run berturut-turut GAGAL, kirim alert.
#
#  PENTING: watchdog HANYA mengalert, TIDAK auto-recover.
#  Baseline listing yang hilang adalah kondisi "tanya human"
#  by design rclone (auto-resync bisa mass-delete bila dua sisi
#  sudah divergen). Recovery manual: lihat gdrive-setup-report.md §8.
# ============================================================

set -u

LOG="/tmp/rclone-bisync.log"
STATE_DIR="$HOME/.cache/rclone"
STATE="$STATE_DIR/bisync-watchdog.state"
ALERT_LOG="$STATE_DIR/bisync-watchdog.log"
ALERT_MARKER="$STATE_DIR/bisync-watchdog.ALERT"
THRESHOLD=3

mkdir -p "$STATE_DIR"

ts() { date '+%Y-%m-%d %H:%M:%S'; }

# ---- baca state ----
COUNTER=0
ALERTED=0
if [ -f "$STATE" ]; then
    v=$(grep -E '^COUNTER=' "$STATE" | cut -d= -f2)
    [ -n "$v" ] && COUNTER=$v
    v=$(grep -E '^ALERTED=' "$STATE" | cut -d= -f2)
    [ -n "$v" ] && ALERTED=$v
fi

# ---- hasil run terakhir di log ----
if [ ! -f "$LOG" ]; then
    LAST=""
else
    # baris pertama dari bawah yang match salah satu hasil run
    LAST=$(tac "$LOG" | grep -m1 -E "Bisync successful|No changes found|Failed to bisync|Bisync aborted")
fi

if [ -z "$LAST" ]; then
    echo "[$(ts)] WATCHDOG: tidak ada hasil bisync di log — skip (counter tetap $COUNTER)"
    exit 0
fi

if echo "$LAST" | grep -qE "Bisync successful|No changes found"; then
    # run bersih
    if [ "$COUNTER" -ne 0 ]; then
        echo "[$(ts)] WATCHDOG: run bersih terdeteksi, reset counter ($COUNTER -> 0)"
    fi
    COUNTER=0
    ALERTED=0
    rm -f "$ALERT_MARKER"
else
    # run gagal
    COUNTER=$((COUNTER + 1))
    echo "[$(ts)] WATCHDOG: run GAGAL terdeteksi (ke-$COUNTER dari $THRESHOLD): ${LAST}"
fi

printf 'COUNTER=%s\nALERTED=%s\n' "$COUNTER" "$ALERTED" > "$STATE"

# ---- alert? ----
if [ "$COUNTER" -ge "$THRESHOLD" ] && [ "$ALERTED" -eq 0 ]; then
    MSG="GDrive bisync macet: $COUNTER run gagal berturut-turut. Perlu --resync manual (lihat gdrive-setup-report.md §8)."
    echo "[$(ts)] WATCHDOG ALERT: $MSG" | tee -a "$ALERT_LOG"
    notify-send -u critical "GDrive bisync STUCK" "$MSG" 2>/dev/null || true
    touch "$ALERT_MARKER"
    ALERTED=1
    printf 'COUNTER=%s\nALERTED=%s\n' "$COUNTER" "$ALERTED" > "$STATE"
fi

exit 0
