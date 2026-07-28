# Linux Stuffs

A personal collection of scripts, configurations, and fixes for Linux.

Current projects:
- **CachyOS NTFS Fix** — dual-boot NTFS mount management (optimized for CachyOS / Arch).
- **GDrive Bisync Sync** — two-way Google Drive sync via `rclone bisync` with systemd timers + a stuck-sync watchdog.

---

## 📂 Project Structure

| Project Name | Description | Link |
| :--- | :--- | :--- |
| **CachyOS NTFS Fix** | Scripts to handle NTFS mounting issues, lock files, and permissions in dual-boot setups. | [View Project](./cachyos-ntfs-fix) |
| **GDrive Bisync Sync** | Two-way Google Drive sync via `rclone bisync` with systemd timers and a stuck-sync watchdog. | [View Project](./gdrive-bisync-sync) |

---

## 🚀 How to Use
Each sub-folder contains its own documentation and installation scripts. Navigate to the specific project folder for detailed instructions.

```bash
cd linux-stuffs/cachyos-ntfs-fix
# or
cd linux-stuffs/gdrive-bisync-sync
```

## 🛠 Prerequisites

* **CachyOS / Arch-based** (NTFS fix): `ntfs-3g`, `bash`
* **Any systemd Linux** (Drive sync): `rclone` (v1.74+), `fuse3`
