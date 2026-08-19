#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLOR_FILE="${SCRIPT_DIR}/colors.sh"
ASSETS_DIR="${SCRIPT_DIR}/assets"
TARGET_DIR="${COZY_UI_DIR:-/home/alice/.var/app/com.usebottles.bottles/data/bottles/bottles/Doki/drive_c/users/steamuser/Desktop/Monika/game/Submods/CozyUI/themes/active}"

if [[ ! -d "$ASSETS_DIR" ]]; then
    echo "Error: Base assets directory not found at $ASSETS_DIR" >&2
    exit 1
fi

if [[ -f "$COLOR_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$COLOR_FILE"
fi

TARGET_HEX="${PRIMARY_LIGHT:-#8c4f26}"
# Strip leading hash or quotes
TARGET_HEX="${TARGET_HEX//[\"# ]/}"

# If it's still an unparsed template tag, fallback to a sensible color
if [[ "$TARGET_HEX" == *"{"* ]] || [[ ${#TARGET_HEX} -lt 6 ]]; then
    TARGET_HEX="8c4f26"
fi

if ! command -v magick >/dev/null 2>&1; then
    echo "Warning: ImageMagick (magick) is not installed; skipping asset recoloring." >&2
    exit 0
fi

echo "Recoloring Cozy UI theme assets in $TARGET_DIR from base assets using primary #$TARGET_HEX..."

# 1. Restore fresh pristine assets into active directory
mkdir -p "$TARGET_DIR"
cp -r "$ASSETS_DIR/button" "$ASSETS_DIR/scrollbar" "$ASSETS_DIR/slider" "$ASSETS_DIR/replacers" "$TARGET_DIR/"

# 2. Compute exact Hue Delta using python3
MOD_VALUES=$(python3 -c "
import colorsys
hex_val = '$TARGET_HEX'
try:
    r, g, b = [int(hex_val[i:i+2], 16)/255.0 for i in (0, 2, 4)]
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    target_hue = h * 360.0
    base_hue = 145.0  # Original Cozy UI theme base green
    delta = target_hue - base_hue
    while delta < -180: delta += 360
    while delta > 180: delta -= 360
    mod_hue = 100.0 + (delta / 180.0 * 100.0)
    print(f'{mod_hue:.1f}')
except Exception:
    print('100.0')
")

HUE_VAL="${MOD_VALUES}"

# 3. Collect all themeable PNG assets (excluding chess pieces and unstyled icons)
mapfile -t FILES < <(find \
    "$TARGET_DIR/button" \
    "$TARGET_DIR/scrollbar" \
    "$TARGET_DIR/slider" \
    "$TARGET_DIR/replacers/gui" \
    "$TARGET_DIR/replacers/mod_assets" \
    -name "*.png" \
    ! -path "*/chess/pieces/*" \
    2>/dev/null || true)

if [[ ${#FILES[@]} -gt 0 ]]; then
    echo "Applying hue modulation (hue: $HUE_VAL) to ${#FILES[@]} UI assets..."
    # Batch recolor with ImageMagick preserving all gradients, highlights, and transparency
    magick mogrify -modulate "100,100,${HUE_VAL}" "${FILES[@]}"
fi

echo "Cozy UI theme assets successfully recolored!"
