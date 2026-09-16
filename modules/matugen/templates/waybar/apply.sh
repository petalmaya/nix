#!/usr/bin/env bash
set -euo pipefail
# waybar reload — SIGUSR2 triggers css reload without restart (waybar ≥0.9)
if pgrep -x waybar >/dev/null 2>&1; then
  pkill -SIGUSR2 waybar 2>/dev/null || pkill -x waybar 2>/dev/null || true
  # fallback: restart if SIGUSR2 not supported
  (sleep 0.5; pgrep -x waybar >/dev/null 2>&1 || waybar >/dev/null 2>&1 & disown) &
fi
