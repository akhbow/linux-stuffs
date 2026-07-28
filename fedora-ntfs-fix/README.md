# 🐧 Fedora NTFS Mount Setup
> Dual-driver NTFS mounting on Fedora (internal SATA HDDs + NVMe Windows partition + external HDD).

This folder documents a working Fedora setup that mounts **several** Windows NTFS
partitions at boot via `/etc/fstab`, using **two different NTFS drivers** on purpose:

| Mount point | What it is | Driver | Why this driver |
| :--- | :--- | :--- | :--- |
| `/mnt/win-3.6t` | Internal SATA HDD A | `ntfs-3g` (userspace/FUSE) | Mature, reliable for large spinning disks |
| `/mnt/win-1.8t` | Internal SATA HDD B | `ntfs-3g` (userspace/FUSE) | Same as above |
| `/mnt/win-c` | NVMe Windows **C:** partition | `ntfs3` (in-kernel) | Fast kernel driver, no FUSE overhead |
| `/mnt/win-931g` | External HDD (removable) | `ntfs3` (in-kernel, `force`) | External disks often get left "dirty" by Windows; `force` still mounts them |

> **Security note:** this repo contains **no credentials and no real disk UUIDs**.
> Every `<UUID>` below is a placeholder — substitute your own with `blkid -U` /
> `lsblk -f`. Your actual values live in `/etc/fstab` on the machine.

---

## 📦 What's in here

| Path | What |
| :--- | :--- |
| `scripts/fix_fedora_ntfs.sh` | One-shot setup: install `ntfs-3g`, create mount points, clear dirty flags, print the fstab template. |
| `scripts/mount_external.sh` | Mount the external HDD by UUID with the `ntfs3` kernel driver (+ `force` for dirty disks). |
| `configs/fstab.example` | Templated `/etc/fstab` NTFS entries (fill in your UUIDs). |

---

## 🔍 The core problem (same as every dual-boot)

Windows (Fast Startup / Hibernation) leaves NTFS partitions in a **"dirty"** state.
Linux refuses write access to avoid corruption. Fix: **`ntfsfix`** clears the dirty
flag non-destructively (no `chkdsk` needed). Then mount with the right driver.

---

## 🚀 Setup

### 1. Install `ntfs-3g` (the kernel `ntfs3` driver needs no install)
```bash
sudo dnf install -y ntfs-3g
```

### 2. Create mount points
```bash
sudo mkdir -p /mnt/win-3.6t /mnt/win-1.8t /mnt/win-931g /mnt/win-c
```

### 3. Clear dirty flags on present internal partitions
```bash
# replace with YOUR device paths from `lsblk -f`
sudo ntfsfix /dev/sdX2   # internal HDD A
sudo ntfsfix /dev/sdY2   # internal HDD B
```

### 4. Add the fstab entries (templated in `configs/fstab.example`)
```bash
sudoedit /etc/fstab
# paste the 4 lines, substituting <UUID> with values from `lsblk -f`
sudo mount -a        # mount everything (or just reboot)
```

### 5. External HDD
The external disk may be powered off (then it simply won't mount — that's expected,
`nofail` keeps boot clean). When it's on, mount it with:
```bash
./scripts/mount_external.sh
```
It finds the disk by UUID, clears the dirty flag, and mounts with `ntfs3 force`.

---

## 🔧 Why two drivers? (`ntfs-3g` vs `ntfs3`)
- **`ntfs3`** is the modern in-kernel driver — faster, lower overhead, good for the
  NVMe system partition and removable disks.
- **`ntfs-3g`** is the long-standing FUSE/userspace driver — extremely mature, handles
  edge cases some setups still hit on big spinning HDDs.
- Both are fine; the mix here is just what was verified working on this Fedora box.
  You can switch any line to `ntfs3` (drop `force` for internal disks) if you prefer.

### Mount-option notes
| Option | Effect |
| :--- | :--- |
| `uid=1000,gid=1000` | Own the mount as your user (no `sudo` needed to read/write). |
| `windows_names` | Reject filenames invalid on Windows (avoids cross-OS surprises). |
| `noatime` | Don't update access time on read — less wear on HDDs, faster. |
| `nofail` | Boot won't hang if the disk (esp. external) is absent. |
| `force` (external only) | Mount even if the dirty flag is set (after `ntfsfix`). |

---

## ✅ Verification
```bash
mount | grep win-        # confirm all expected mounts are up
ls -ld /mnt/win-*      # should be your user (drwxr-xr-x, owner 1000)
ls /mnt/win-3.6t       # should list files (read/write)
```

---

*Created by [Dwi Wahyu Prabowo](https://github.com/akhbow/)*
