#!/bin/bash
# 1. Install driver
sudo pacman -S --needed --noconfirm ntfs-3g

# 2. Create directory
sudo mkdir -p /mnt/data_laptop

# 3. Clear NTFS dirty bit
sudo ntfsfix /dev/sda1

# 4. Mount with Read/Write/Delete permissions (umask=000)
sudo umount /mnt/data_laptop 2>/dev/null
sudo mount -t ntfs-3g /dev/sda1 /mnt/data_laptop -o uid=1000,gid=1000,umask=000

# 5. Persistent Automounting
# Removes old entries to prevent duplicates and adds fresh config
sudo sed -i '/6CF2A2EFF2A2BD28/d' /etc/fstab
echo "UUID=6CF2A2EFF2A2BD28 /mnt/data_laptop ntfs-3g defaults,nofail,uid=1000,gid=1000,umask=000 0 0" | sudo tee -a /etc/fstab

echo "Laptop Mounting Complete."
