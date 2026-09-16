#!/usr/bin/env bash
set -euo pipefail
# no-op: sway theme lives at ~/.local/state/nixtop/theme/sway (not inside ~/.config/sway)
# This undo just reloads sway to fall back to the static mineral-blue palette.
if command -v swaymsg >/dev/null 2>&1 && pgrep -x sway >/dev/null 2>&1; then
  swaymsg reload 2>/dev/null || true
fi
