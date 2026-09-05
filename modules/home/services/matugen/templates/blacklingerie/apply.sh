#!/usr/bin/env bash
# apply.sh — Recolors the kroniichiiwa blacklingerie jacket sprites to cute
# Trans Pride colors (or matugen / custom colors) while strictly preserving
# Monika's skin tones, black lace, and white trims.
#
# Trans Pride Presets:
#   - trans / pink : Pastel Trans Pride Pink (#F5A9B8) [Default]
#   - blue / cyan  : Pastel Trans Pride Cyan/Blue (#5BCEFA)
#   - matugen      : Current matugen theme accent color
#   - <HEX>        : Custom hex code (e.g. #FF70A6)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLOR_FILE="${SCRIPT_DIR}/colors.sh"
ORIGINALS_DIR="${SCRIPT_DIR}/originals"

TARGET_DIRS=(
    "${BLACKLINGERIE_DIR:-/home/alice/Monika/game/mod_assets/monika/c/kroniichiiwa_blacklingerie_jacket}"
    "$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/Doki/drive_c/users/steamuser/Desktop/Monika/game/mod_assets/monika/c/kroniichiiwa_blacklingerie_jacket"
)

MODE="${1:-trans}"

if [[ ! -d "$ORIGINALS_DIR" ]]; then
    echo "Error: Pristine originals directory not found at $ORIGINALS_DIR" >&2
    exit 1
fi

python3 - <<EOF
import os, sys, glob, colorsys, subprocess

mode = "$MODE".lower()
color_file = "$COLOR_FILE"
originals_dir = "$ORIGINALS_DIR"
target_dirs = [
    "${BLACKLINGERIE_DIR:-/home/alice/Monika/game/mod_assets/monika/c/kroniichiiwa_blacklingerie_jacket}",
    os.path.expanduser("~/.var/app/com.usebottles.bottles/data/bottles/bottles/Doki/drive_c/users/steamuser/Desktop/Monika/game/mod_assets/monika/c/kroniichiiwa_blacklingerie_jacket")
]

# Determine target hex and hue
target_hex = "F5A9B8" # Default Trans Pink
theme_name = "Trans Pride Pink (#F5A9B8)"

if mode in ("trans", "pink", "trans-pink"):
    target_hex = "F5A9B8"
    theme_name = "Trans Pride Pink (#F5A9B8)"
elif mode in ("blue", "cyan", "trans-blue"):
    target_hex = "5BCEFA"
    theme_name = "Trans Pride Blue (#5BCEFA)"
elif mode == "matugen":
    if os.path.exists(color_file):
        with open(color_file, "r") as f:
            for line in f:
                if line.startswith("TERTIARY_DARK=") or line.startswith("PRIMARY_DARK="):
                    val = line.split("=")[1].strip().replace('"', '').replace("'", '').replace('#', '')
                    if len(val) >= 6 and "{" not in val:
                        target_hex = val[:6]
                        break
    theme_name = f"Matugen Theme (#{target_hex})"
else:
    clean_hex = mode.replace("#", "").replace('"', '').replace("'", "")
    if len(clean_hex) == 6:
        target_hex = clean_hex
        theme_name = f"Custom (#{target_hex})"

print(f"🏳️‍⚧️ Recoloring Monika's Black Lingerie Jacket Sprites")
print(f"  Theme       : {theme_name}")
print(f"  Target Hex  : #{target_hex}")
print(f"  Source Base : {originals_dir}")

# Compute target HSV
tr, tg, tb = [int(target_hex[i:i+2], 16) / 255.0 for i in (0, 2, 4)]
target_h, target_s, target_v = colorsys.rgb_to_hsv(tr, tg, tb)

# Gather source sprites
src_files = sorted(glob.glob(os.path.join(originals_dir, "*.png")))
if not src_files:
    print(f"No sprites found in {originals_dir}!")
    sys.exit(1)

for target_dir in target_dirs:
    if not os.path.isdir(os.path.dirname(target_dir)):
        continue

    os.makedirs(target_dir, exist_ok=True)
    print(f"  Applying to : {target_dir}")
    recolored_count = 0

    for src_path in src_files:
        fname = os.path.basename(src_path)
        dst_path = os.path.join(target_dir, fname)

        # Read raw RGBA via magick
        res = subprocess.run(["magick", src_path, "rgba:-"], capture_output=True)
        raw = bytearray(res.stdout)
        if len(raw) == 0:
            continue

        # Collect unique colors
        unique_colors = set()
        for i in range(0, len(raw), 4):
            if raw[i+3] > 0:
                unique_colors.add((raw[i], raw[i+1], raw[i+2]))

        # Build selective LUT (preserve skin 20°-90° and neutral lace, transform only blue/violet accents 170°-285°)
        lut = {}
        for r, g, b in unique_colors:
            rf, gf, bf = r / 255.0, g / 255.0, b / 255.0
            h, s, v = colorsys.rgb_to_hsv(rf, gf, bf)
            hdeg = h * 360.0

            if 170.0 <= hdeg <= 285.0 and s > 0.08 and v > 0.05:
                if mode in ("trans", "pink", "trans-pink"):
                    # Cute Pastel Trans Pink
                    new_h = 348.5 / 360.0
                    new_s = min(1.0, max(s * 1.1, 0.42))
                    new_v = min(1.0, v * 1.05)
                elif mode in ("blue", "cyan", "trans-blue"):
                    # Cute Pastel Trans Blue
                    new_h = 197.0 / 360.0
                    new_s = min(1.0, max(s * 1.1, 0.52))
                    new_v = min(1.0, v * 1.05)
                else:
                    # Custom / Matugen Hue shift
                    new_h = target_h
                    new_s = min(1.0, max(s, target_s * 0.8))
                    new_v = v

                nr, ng, nb = colorsys.hsv_to_rgb(new_h, new_s, new_v)
                lut[(r, g, b)] = (int(round(nr * 255)), int(round(ng * 255)), int(round(nb * 255)))

        # Apply LUT
        for i in range(0, len(raw), 4):
            if raw[i+3] > 0:
                k = (raw[i], raw[i+1], raw[i+2])
                if k in lut:
                    raw[i], raw[i+1], raw[i+2] = lut[k]

        # Write output image
        p_out = subprocess.Popen(
            ["magick", "-size", "1280x850", "-depth", "8", "rgba:-", dst_path],
            stdin=subprocess.PIPE
        )
        p_out.communicate(input=raw)
        recolored_count += 1

    print(f"  ✓ Successfully recolored {recolored_count} sprites (skin tones protected).")

print("Done! Sprites updated to cute Trans Pride colors.")
EOF

