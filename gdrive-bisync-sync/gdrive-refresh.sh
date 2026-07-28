#!/bin/bash

# ============================================================
#  gdrive-refresh.sh — Refresh & Optimasi Rclone Mount
#  Menulis ulang konfigurasi service, membersihkan cache,
#  dan memastikan --no-modtime DIHAPUS agar bisync bisa
#  mendeteksi perubahan file dengan benar.
# ============================================================

echo "=============================================="
echo " Rclone Refresh & Optimasi (Office Workflow)"
echo "=============================================="

# 1. Tulis ulang konfigurasi service systemd
echo ""
echo "[1/6] Memperbarui konfigurasi service systemd..."
cat << EOF > ~/.config/systemd/user/rclone-mount.service
[Unit]
Description=Rclone Google Drive Mount (Office Optimized)
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/rclone mount gdrive: %h/GoogleDrive \\
    --vfs-cache-mode full \\
    --vfs-cache-max-age 2h \\
    --vfs-cache-max-size 5G \\
    --vfs-read-ahead 128k \\
    --dir-cache-time 24h \\
    --attr-timeout 10s \\
    --vfs-fast-fingerprint
ExecStop=/usr/bin/fusermount3 -u %h/GoogleDrive
Restart=on-failure

[Install]
WantedBy=default.target
EOF
echo "     --> Konfigurasi diperbarui (--no-modtime dan --no-checksum dihapus)."

# 2. Hentikan service
echo ""
echo "[2/6] Menghentikan service Rclone..."
systemctl --user stop rclone-mount.service

# 3. Bersihkan cache lama
echo ""
echo "[3/6] Membersihkan cache VFS dan Metadata lama..."
rm -rf ~/.cache/rclone/vfs/gdrive
rm -rf ~/.cache/rclone/vfsMeta/gdrive
echo "     --> Cache dibersihkan."

# 4. Paksa unmount
echo ""
echo "[4/6] Memastikan mount point bersih..."
fusermount3 -uz ~/GoogleDrive 2>/dev/null
echo "     --> Unmount selesai."

# 5. Reload systemd
echo ""
echo "[5/6] Menerapkan konfigurasi systemd baru..."
systemctl --user daemon-reload

# 6. Jalankan kembali service
echo ""
echo "[6/6] Menjalankan kembali service Rclone..."
systemctl --user start rclone-mount.service

# Tunggu sebentar lalu cek status
sleep 3
STATUS=$(systemctl --user is-active rclone-mount.service)

echo ""
echo "=============================================="
if [ "$STATUS" = "active" ]; then
    echo " SELESAI! Service berjalan dengan baik."
    echo " Folder ~/GoogleDrive sudah siap digunakan."
else
    echo " PERHATIAN: Service belum aktif (status: $STATUS)."
    echo " Cek log dengan: journalctl --user -u rclone-mount.service -n 30"
fi
echo "=============================================="
