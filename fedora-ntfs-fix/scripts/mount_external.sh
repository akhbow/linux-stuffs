#!/usr/bin/env bash
# Mount the external NTFS HDD with the ntfs3 kernel driver.
# Uses 'force' so a dirty external disk (left by Windows Fast Startup) still mounts.
# Replace <WIN_931G_UUID> with your disk's UUID (blkid -U / lsblk -f).
set -euo pipefail

TARGET_UUID="<WIN_931G_UUID>"
MOUNT_POINT="/mnt/win-931g"

sudo mkdir -p "$MOUNT_POINT"

DEV_PATH=$(sudo blkid -U "$TARGET_UUID" || true)
if [ -z "$DEV_PATH" ]; then
  echo "ERROR: external disk with UUID '$TARGET_UUID' not found."
  echo "Is it powered on / plugged in? Check with: lsblk -f"
  exit 1
fi

echo "Clearing dirty flag on $DEV_PATH ..."
sudo ntfsfix "$DEV_PATH" || echo "  (ntfsfix skipped — disk may already be clean)"

echo "Mounting $DEV_PATH -> $MOUNT_POINT (ntfs3, force) ..."
sudo mount -t ntfs3 "$DEV_PATH" "$MOUNT_POINT" -o force,uid=1000,gid=1000,windows_names,noatime

echo "Done. External HDD available at $MOUNT_POINT"
