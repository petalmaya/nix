#!/usr/bin/env bash
# apply.sh — Recolors the kroniichiiwa blacklingerie jacket sprites to match
# the current matugen material theme accent color.
#
# Strategy: the original accent is a steel/ice blue at ~195° hue.
# We compute the hue delta from 195° to the target primary color and
# use ImageMagick `mogrify -modulate` to rotate all accent pixels.
#
# Sprites are recolored IN PLACE from the originals stored in ./originals/.
# Run matugen to regenerate colors.sh, which triggers this hook.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLOR_FILE="${SCRIPT_DIR}/colors.sh"
ORIGINALS_DIR="${SCRIPT_DIR}/originals"
TARGET_DIR="${BLACKLINGERIE_DIR:-/home/alice/.var/app/com.usebottles.bottles/data/bottles/bottles/Doki/drive_c/users/steamuser/Desktop/Monika/game/mod_assets/monika/c/kroniichiiwa_blacklingerie_jacket}"

# ── Load matugen-generated colors ──────────────────────────────────────────
if [[ -f "$COLOR_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$COLOR_FILE"
fi

# Pick the best accent: prefer tertiary (often most vibrant/distinct),
# fallback to primary. Use dark variant so it shows well on the dark outfit.
TARGET_HEX="${TERTIARY_DARK:-${PRIMARY_DARK:-#8c4f26}}"
# Strip leading # and any quotes/spaces
TARGET_HEX="${TARGET_HEX//[\"# ]/}"

# Guard against un-rendered template tags (shouldn't happen post-matugen)
if [[ "$TARGET_HEX" == *"{"* ]] || [[ ${#TARGET_HEX} -lt 6 ]]; then
    echo "Warning: color not resolved, using fallback." >&2
    TARGET_HEX="6DA1B6"  # original accent as safe fallback (no-op)
fi

# ── Dependency check ───────────────────────────────────────────────────────
if ! command -v magick >/dev/null 2>&1; then
    echo "Warning: ImageMagick (magick) not found; skipping sprite recolor." >&2
    exit 0
fi

# ── Seed originals on first run ────────────────────────────────────────────
# We keep a pristine copy of all sprites so every matugen run starts fresh.
if [[ ! -d "$ORIGINALS_DIR" ]]; then
    echo "First run: backing up original sprites to $ORIGINALS_DIR ..."
    mkdir -p "$ORIGINALS_DIR"
    cp "$TARGET_DIR"/*.png "$ORIGINALS_DIR/"
fi

# ── Compute hue delta (base 195° → target) ─────────────────────────────────
# magick -modulate uses: brightness,saturation,hue where hue is 0-200
# (100 = no change, 0/200 = full rotation = 180°). We map our delta accordingly.
HUE_VAL=$(python3 -c "
import colorsys
hex_val = '$TARGET_HEX'
try:
    r, g, b = [int(hex_val[i:i+2], 16) / 255.0 for i in (0, 2, 4)]
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    target_hue = h * 360.0
    base_hue   = 195.0  # original steel-blue accent hue of the sprites
    delta = target_hue - base_hue
    while delta < -180: delta += 360
    while delta >  180: delta -= 360
    # Map delta (-180..180) → modulate hue (0..200), 100 = identity
    mod_hue = 100.0 + (delta / 180.0 * 100.0)
    print(f'{mod_hue:.2f}')
except Exception:
    print('100.00')
")

echo "Recoloring kroniichiiwa blacklingerie sprites:"
echo "  Target hex : #$TARGET_HEX"
echo "  Hue modulate: $HUE_VAL  (100 = no change)"
echo "  Source originals: $ORIGINALS_DIR"
echo "  Output sprites : $TARGET_DIR"

# ── Restore pristine originals then recolor ────────────────────────────────
mkdir -p "$TARGET_DIR"
cp "$ORIGINALS_DIR"/*.png "$TARGET_DIR/"

mapfile -t FILES < <(find "$TARGET_DIR" -maxdepth 1 -name "*.png" 2>/dev/null || true)

if [[ ${#FILES[@]} -gt 0 ]]; then
    echo "Applying hue modulation to ${#FILES[@]} sprites..."
    # -modulate brightness,saturation,hue
    # We only shift hue; keep brightness and saturation at 100 (unchanged).
    magick mogrify -modulate "100,100,${HUE_VAL}" "${FILES[@]}"
    echo "Done! ${#FILES[@]} sprites recolored."
else
    echo "No PNG files found in $TARGET_DIR."
fi
