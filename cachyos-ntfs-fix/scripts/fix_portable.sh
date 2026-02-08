#!/bin/bash

# 1. Define the device path (Check 'lsblk' to ensure it's sdc2)
DEV_PATH="/dev/sdc2"
MOUNT_POINT="/mnt/portable"

# 2. Ensure mount point exists
echo "Preparing mount point at $MOUNT_POINT..."
sudo mkdir -p $MOUNT_POINT

# 3. Clear NTFS "dirty" flag
echo "Fixing NTFS state on $DEV_PATH..."
sudo ntfsfix $DEV_PATH

# 4. Mount using the modern ntfs3 driver with full permissions
echo "Mounting $DEV_PATH to $MOUNT_POINT..."
# We use -o force for the ntfs3 driver to bypass journal errors
sudo mount -t ntfs3 $DEV_PATH $MOUNT_POINT -o force,uid=1000,gid=1000,umask=000

echo "-------------------------------------------------------"
echo "Portable drive is ready at $MOUNT_POINT"
