# 🛠️ Dual-Boot NTFS Mount Management
> Optimized for CachyOS (Arch-based) & Windows 11 Environments.

This repository contains scripts and configurations to resolve common mounting issues in a dual-boot setup. It specifically addresses "Locked/Dirty Partition" errors and permission issues (Read-only access) when accessing Windows drives from Linux.

---

## ⚠️ The Core Problem
Windows 11 often leaves NTFS partitions in a **"dirty"** state due to **Fast Startup** or **Hibernation**. Linux kernels (even with `ntfs-3g` or `ntfs3`) will refuse to mount these with write access to prevent data corruption.

### Prerequisites (Run in Windows 11)
Before using these scripts, ensure the following:
1. **Disable Hibernation:** Open CMD as Admin and run `powercfg /h off`.
2. **Disable Fast Startup:** Found in Control Panel > Power Options.
3. **Power Action:** Always use **Restart** instead of Shutdown when switching to Linux.

---

## 📁 Repository Structure
* `/scripts`: Contains automation scripts for different hardware setups.
* `/configs`: Example snippets for `/etc/fstab`.

---

## 🚀 Usage

### 1. PC Setup (Dual Internal Drives)
For desktops with multiple internal drives (e.g., `/dev/sda2` and `/dev/sdb2`).
```bash
chmod +x scripts/fix_pc_mount.sh
./scripts/fix_pc_mount.sh


```

### 2. Laptop Setup (Single Drive + Secondary HDD)

For laptops with a secondary storage partition (e.g., `/dev/sda1`).

```bash
chmod +x scripts/fix_laptop_mount.sh
./scripts/fix_laptop_mount.sh

```

### 3. Portable Hard Drive Fix

If an external drive fails to mount via File Manager (Dolphin/Thunar), use the force mount script:

```bash
sudo ./scripts/fix_portable.sh

```

---

## 🛠️ Technical Details: Mount Options

| Option | Description |
| --- | --- |
| `uid=1000` | Assigns ownership to your primary Linux user. |
| `gid=1000` | Assigns ownership to your primary group. |
| `umask=000` | Grants full Read/Write/Delete permissions (777). |
| `nofail` | System will still boot even if the drive is missing. |

---

## ✅ Verification

To verify your mount permissions, run:

```bash
ls -ld /mnt/data_laptop

```

The output should start with `drwxrwxrwx`, indicating full access.

---

*Created by [Dwi Wahyu Prabowo*](https://github.com/akhbow/)

```

---