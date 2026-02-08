#!/bin/bash
# Install driver
sudo pacman -S --needed --noconfirm ntfs-3g

# Create mount points
sudo mkdir -p /mnt/data_a /mnt/data_b

# Fix NTFS Lock
sudo ntfsfix /dev/sda2
sudo ntfsfix /dev/sdb2

# Temporary Mount with Full Access
sudo mount -t ntfs-3g /dev/sda2 /mnt/data_a -o uid=1000,gid=1000,umask=000
sudo mount -t ntfs-3g /dev/sdb2 /mnt/data_b -o uid=1000,gid=1000,umask=000

# Permanent Configuration (/etc/fstab)
# Replace UUIDs with your specific drive UUIDs
echo "UUID=8ADC2040DC202941 /mnt/data_a ntfs-3g defaults,nofail,uid=1000,gid=1000,umask=000 0 0" | sudo tee -a /etc/fstab
echo "UUID=B85C56685C562204 /mnt/data_b ntfs-3g defaults,nofail,uid=1000,gid=1000,umask=000 0 0" | sudo tee -a /etc/fstab
