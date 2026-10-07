#!/usr/bin/env bash
# Shows the serial log (Ctrl-] to quit). Resets the board.
set -euo pipefail
. "$(dirname "$0")/env.sh"
idf_env
find_port
cd "$SDK_DIR/esp32"
idf.py -B "$BUILD_DIR" -p "$PORT" monitor
