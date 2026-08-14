#!/usr/bin/env bash
# lenovo-battery-apply.sh
# Terapkan profil baterai awet (conservation) untuk Lenovo IdeaPad laptop.
# Jalankan sbg root.
#
# PENTING (hasil debug 2026-08-13):
#   Menulis ke charge_types MEMRESET conservation_mode ke 0.
#   Jadi: JANGAN sentuh charge_types. Cukup set conservation_mode=1
#   (batasi charge ~60%, paling awet - ini yang Dr. Dwi mau).
set -u
CONS=$(find /sys -name conservation_mode -print -quit 2>/dev/null || true)
if [[ -n "$CONS" ]]; then
    printf '1' > "$CONS"
fi
echo "lenovo-battery: profil conservation (awet, ~60%) diterapkan."
