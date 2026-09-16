#!/usr/bin/env bash
set -euo pipefail
# sway theme is at ~/.local/state/nixtop/theme/sway, already included from sway/config.
# This hook just reloads sway so the new colors take effect live.
if command -v swaymsg >/dev/null 2>&1 && pgrep -x sway >/dev/null 2>&1; then
  swaymsg reload 2>/dev/null || true
fi
# also poke waybar in case sway's border changes affect bar contrast
if pgrep -x waybar >/dev/null 2>&1; then
  pkill -SIGUSR2 waybar 2>/dev/null || true
fi
