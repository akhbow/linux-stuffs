# Linux Stuffs

A personal collection of scripts, configurations, and fixes for Linux.

Current projects:
- **CachyOS NTFS Fix** — dual-boot NTFS mount management (optimized for CachyOS / Arch).
- **Fedora NTFS Fix** — dual-driver (ntfs-3g + ntfs3) NTFS mount setup for Fedora.
- **GDrive Bisync Sync** — two-way Google Drive sync via `rclone bisync` with systemd timers + a stuck-sync watchdog.
- **Fastfetch Config** — boxed hardware/software/uptime layout for `fastfetch` (Fedora).
- **Lenovo IdeaPad Battery Profile** — `conservation_mode` (~60%) battery limit for Lenovo IdeaPad on Fedora via `lenovoctl` CLI + systemd boot service.

---

## 📂 Project Structure

| Project Name | Description | Link |
| :--- | :--- | :--- |
| **CachyOS NTFS Fix** | Scripts to handle NTFS mounting issues, lock files, and permissions in dual-boot setups. | [View Project](./cachyos-ntfs-fix) |
| **Fedora NTFS Fix** | Dual-driver (`ntfs-3g` + `ntfs3`) NTFS mount setup for Fedora (internal + external disks). | [View Project](./fedora-ntfs-fix) |
| **GDrive Bisync Sync** | Two-way Google Drive sync via `rclone bisync` with systemd timers and a stuck-sync watchdog. | [View Project](./gdrive-bisync-sync) |
| **Fastfetch Config** | Boxed hardware/software/uptime layout for `fastfetch` (Fedora). | [View Project](./fastfetch-config) |
| **Lenovo IdeaPad Battery Profile** | `conservation_mode` (~60%) battery limit for Lenovo IdeaPad on Fedora via `lenovoctl` CLI + systemd boot service. | [View Project](./lenovo-ideapad-battery-profile) |

---

## 🚀 How to Use
Each sub-folder contains its own documentation and installation scripts. Navigate to the specific project folder for detailed instructions.

```bash
cd linux-stuffs/cachyos-ntfs-fix
# or
cd linux-stuffs/fedora-ntfs-fix
# or
cd linux-stuffs/gdrive-bisync-sync
# or
cd linux-stuffs/lenovo-ideapad-battery-profile
```

## 🛠 Prerequisites

* **CachyOS / Arch-based** (NTFS fix): `ntfs-3g`, `bash`
* **Fedora** (NTFS fix): `ntfs-3g` (kernel `ntfs3` is built-in), `bash`, `dnf`
* **Any systemd Linux** (Drive sync): `rclone` (v1.74+), `fuse3`
* **Fedora / systemd Linux** (Lenovo battery): `bash`, `systemd`, root/sudo for sysfs writes
