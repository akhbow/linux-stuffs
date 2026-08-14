# Lenovo Battery Conservation (Fedora / IdeaPad)

Scripts to cap Lenovo IdeaPad battery charging at ~60% (battery-saver /
`conservation_mode`) so the battery lasts longer when the laptop is always
plugged in.

## Machine facts
- Laptop: Lenovo IdeaPad, Fedora 44, battery `BAT1`.
- Two sysfs APIs: `conservation_mode` (binary 0/1) and `charge_types`
  (`Fast` / `Standard` / `Long_Life`).
- **Source of truth = `conservation_mode`** (caps at ~60%, best for longevity).
- `charge_types` is NOT stable on this machine (the kernel falls back to
  `Standard`) and writing to it **resets `conservation_mode` to 0** — do not use it.

## Files
| File | Purpose |
|------|---------|
| `lenovoctl` | CLI utility: `status`, `doctor`, `battery long-life/standard/fast`, `fn on/off`, `usb on/off`. Reads & writes `conservation_mode`. |
| `lenovo-battery-apply.sh` | Only sets `conservation_mode=1`. Runs at boot. |
| `lenovo-battery.service` | systemd unit (oneshot, `WantedBy=multi-user.target`) → runs `lenovo-battery-apply.sh` at every boot so the profile persists. |

## Install (root)
```bash
install -m 755 lenovoctl /usr/local/bin/lenovoctl
install -m 755 lenovo-battery-apply.sh /usr/local/bin/lenovo-battery-apply.sh
install -m 644 lenovo-battery.service /etc/systemd/system/lenovo-battery.service
systemctl daemon-reload
systemctl enable --now lenovo-battery.service
```

## Daily usage
```bash
lenovoctl status                 # Battery -> "Long Life (conservation ~60%)"
lenovoctl battery long-life      # cap at ~60% (default, when always plugged in)
lenovoctl battery standard       # charge to 100% (when travelling)
```

Note: `lenovoctl` uses `sudo tee` internally, so it needs sudo when run manually.
At boot, `lenovo-battery.service` runs as root (without a password).
