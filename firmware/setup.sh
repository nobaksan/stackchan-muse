#!/usr/bin/env bash
# Clones the Muse Gadget SDK at the tested commit, applies the StackChan patch
# and regenerates the caption font with Hangul. Safe to run twice.
set -euo pipefail
. "$(dirname "$0")/env.sh"

if [ ! -d "$SDK_DIR/.git" ]; then
    git clone "$SDK_REPO" "$SDK_DIR"
fi
git -C "$SDK_DIR" fetch -q origin "$SDK_REV" 2>/dev/null || true

if git -C "$SDK_DIR" apply --reverse --check "$HERE/muse-stackchan.patch" 2>/dev/null; then
    echo "Patch already applied."
else
    git -C "$SDK_DIR" checkout -q "$SDK_REV"
    git -C "$SDK_DIR" apply "$HERE/muse-stackchan.patch"
    echo "Patch applied on $(git -C "$SDK_DIR" rev-parse --short HEAD)."
fi

# The caption font is ~10 MB of generated C, so it isn't in the patch: build it
# here from GNU Unifont (needs curl and npx/Node.js, about 2 minutes).
if ! grep -q "0xAC00-0xD7A3" "$SDK_DIR/esp32/components/muse/fonts/muse_font_cjk_16.c" 2>/dev/null; then
    sh "$SDK_DIR/esp32/tools/muse/gen_cjk_font.sh"
fi
echo "Ready. Next: cp sdkconfig.local-token.example sdkconfig.local-token, add your token, then ./build.sh"
