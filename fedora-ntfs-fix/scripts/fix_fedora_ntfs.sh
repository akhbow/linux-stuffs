#!/usr/bin/env bash
# Fedora NTFS mount setup — internal + external Windows partitions.
# Adapted for Fedora (dnf). Supports both ntfs-3g (userspace) and ntfs3 (kernel).
# No real UUIDs are hardcoded; edit the device list / fstab for YOUR machine.
set -euo pipefail

echo "== Fedora NTFS mount setup =="

# 1. Ensure ntfs-3g is available (ntfs3 is built into the Fedora kernel)
if ! command -v ntfs-3g >/dev/null 2>&1; then
  echo "Installing ntfs-3g via dnf..."
  sudo dnf install -y ntfs-3g
else
  echo "ntfs-3g already present."
fi

# 2. Create mount points
sudo mkdir -p /mnt/win-3.6t /mnt/win-1.8t /mnt/win-931g /mnt/win-c
echo "Mount points ready under /mnt/win-*"

# 3. Clear dirty flags on PRESENT internal Windows partitions (non-destructive).
#    Edit this list to match YOUR disks (see: lsblk -f).
for dev in /dev/sdX2 /dev/sdY2; do
  if [ -b "$dev" ]; then
    echo "Clearing dirty flag on $dev ..."
    sudo ntfsfix "$dev" || echo "  (ntfsfix skipped/failed on $dev — may be clean or already mounted)"
  fi
done

# 4. Print the fstab template to add (substitute your own UUIDs via blkid -U)
echo ""
echo "== Add the following to /etc/fstab (replace <UUID> with 'lsblk -f' values) =="
cat <<'EOF'
# Internal HDD A (ntfs-3g, userspace)
UUID=<WIN_3_6T_UUID>  /mnt/win-3.6t   ntfs-3g  uid=1000,gid=1000,windows_names,noatime,nofail  0  0
# Internal HDD B (ntfs-3g, userspace)
UUID=<WIN_1_8T_UUID>  /mnt/win-1.8t   ntfs-3g  uid=1000,gid=1000,windows_names,noatime,nofail  0  0
# External HDD (ntfs3 kernel driver, 'force' for dirty external disks)
UUID=<WIN_931G_UUID>  /mnt/win-931g   ntfs3  uid=1000,gid=1000,windows_names,noatime,nofail,force  0  0
# Windows C: (NVMe, ntfs3 kernel driver)
UUID=<WIN_C_UUID>     /mnt/win-c      ntfs3  uid=1000,gid=1000,windows_names,noatime,nofail  0  0
EOF

echo ""
echo "Then apply:  sudo mount -a   (or just reboot)"
echo "External HDD (when powered on):  ./scripts/mount_external.sh"
