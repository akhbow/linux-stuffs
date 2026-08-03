# Fastfetch Config

My personal [`fastfetch`](https://github.com/fastfetch-cli/fastfetch) configuration (Fedora 44, fastfetch 2.66.0).

## Layout

The config (`config.jsonc`) renders a boxed, two-section system summary beside the built-in Fedora logo:

- **Hardware** — CPU, GPU, RAM, Disk
- **Software** — OS, Kernel, DE, WM/Type, Packages, Shell, Terminal
- **Uptime / Age** — uptime + total OS age (days since `/` was created, via `stat -c %W`)
- Color blocks (rect) at the bottom

## Install

```bash
# System-wide or per-user
mkdir -p ~/.config/fastfetch
cp config.jsonc ~/.config/fastfetch/config.jsonc

# Verify
fastfetch
```

Requires `fastfetch` ≥ 2.x. Box-drawing characters assume a UTF-8 terminal.
