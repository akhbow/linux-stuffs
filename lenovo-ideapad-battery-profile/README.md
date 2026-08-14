# Lenovo Battery Conservation (Fedora / IdeaPad)

Skrip untuk membatasi charge baterai Lenovo IdeaPad di ~60% (mode awet /
`conservation_mode`) agar baterai tahan lama saat selalu colok charger.

## Fakta mesin
- Laptop: Lenovo IdeaPad, Fedora 44, baterai `BAT1`.
- Dua sysfs API: `conservation_mode` (biner 0/1) dan `charge_types`
  (`Fast`/`Standard`/`Long_Life`).
- **Sumber kebenaran = `conservation_mode`** (batas ~60%, paling awet).
- `charge_types` TIDAK stabil di mesin ini (kernel fallback ke `Standard`)
  dan menulisnya **me-reset `conservation_mode` ke 0** — jangan digunakan.

## File
| File | Fungsi |
|------|--------|
| `lenovoctl` | CLI util: `status`, `doctor`, `battery long-life/standard/fast`, `fn on/off`, `usb on/off`. Membaca & menulis `conservation_mode`. |
| `lenovo-battery-apply.sh` | Hanya set `conservation_mode=1`. Dipanggil saat boot. |
| `lenovo-battery.service` | systemd unit (oneshot, `WantedBy=multi-user.target`) → jalan `lenovo-battery-apply.sh` tiap boot supaya profil persisten. |

## Install (root)
```bash
install -m 755 lenovoctl /usr/local/bin/lenovoctl
install -m 755 lenovo-battery-apply.sh /usr/local/bin/lenovo-battery-apply.sh
install -m 644 lenovo-battery.service /etc/systemd/system/lenovo-battery.service
systemctl daemon-reload
systemctl enable --now lenovo-battery.service
```

## Pakai (harian)
```bash
lenovoctl status                 # Battery -> "Long Life (conservation ~60%)"
lenovoctl battery long-life      # batas ~60% (default, colok terus)
lenovoctl battery standard       # isi penuh 100% (saat travel)
```

Catatan: `lenovoctl` pakai `sudo tee` di dalamnya, jadi butuh sudo saat dijalankan
manual. Saat boot, `lenovo-battery.service` jalan sebagai root (tanpa password).
