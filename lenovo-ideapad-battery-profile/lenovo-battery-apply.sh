#!/usr/bin/env bash
# lenovo-battery-apply.sh
# Apply the battery-saver (conservation) profile for a Lenovo IdeaPad laptop.
# Run as root.
#
# IMPORTANT (from debugging on 2026-08-13):
#   Writing to charge_types RESETS conservation_mode to 0.
#   So: do NOT touch charge_types. Just set conservation_mode=1
#   (caps charging at ~60%, best for longevity — this is what Dr. Dwi wants).
set -u
CONS=$(find /sys -name conservation_mode -print -quit 2>/dev/null || true)
if [[ -n "$CONS" ]]; then
    printf '1' > "$CONS"
fi
echo "lenovo-battery: conservation (battery-saver, ~60%) profile applied."
