#!/usr/bin/env bash
# Reads the whole 16 MB flash to a file and verifies it against the board.
# Do this before flashing anything: it's the only way back to the factory firmware.
set -euo pipefail
. "$(dirname "$0")/env.sh"
find_port
OUT="${1:-stackchan_backup_$(date +%Y%m%d_%H%M%S).bin}"
ESPTOOL="${ESPTOOL:-python3 -m esptool}"
$ESPTOOL --port "$PORT" --baud 460800 read-flash 0 0x1000000 "$OUT"
$ESPTOOL --port "$PORT" --baud 460800 verify-flash 0 "$OUT"
shasum -a 256 "$OUT"
echo "Backup: $OUT  (keep it private: it holds your Wi-Fi password and device tokens)"
