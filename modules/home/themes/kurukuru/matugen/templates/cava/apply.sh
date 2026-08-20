#!/usr/bin/env bash
set -euo pipefail

config_file="${XDG_CONFIG_HOME:-$HOME/.config}/cava/config"
theme_file="${XDG_CONFIG_HOME:-$HOME/.config}/cava/themes/flutterice"

if [ ! -f "$config_file" ] || [ ! -f "$theme_file" ]; then
    exit 0
fi

tmp_file="$(mktemp /tmp/cava_config.XXXXXX)"

# Remove existing [color] section and append the generated theme
sed '/^\[color\]/,$d' "$config_file" > "$tmp_file"
cat "$theme_file" >> "$tmp_file"

if ! cmp -s "$config_file" "$tmp_file"; then
    cp "$tmp_file" "$config_file"
fi
rm -f "$tmp_file"

if pgrep -x cava >/dev/null; then
    pkill -USR1 -x cava || true
fi


