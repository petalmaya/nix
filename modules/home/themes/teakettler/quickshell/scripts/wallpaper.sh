#!/usr/bin/env bash
# Desktop wallpapers via swaybg, theming via matugen. Quickshell owns
# ~/.config/teakettler/config.json; this script only reads it and applies.
#
# Usage:
#   wallpaper.sh apply '<wallpapers-json>' [retheme-image]  live pick from the shell
#   wallpaper.sh retheme <image>                            lock-screen pick (theme only)
#   wallpaper.sh restore                                    login autostart (wallpapers only)
set -euo pipefail

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/teakettler/config.json"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/teakettler"
mkdir -p "$CACHE"

strip_url() { echo "${1#file://}"; }

retheme() {
  local src; src=$(strip_url "$1")
  command -v matugen &>/dev/null || { echo "[INFO] matugen not installed, skipping theme generation"; return 0; }
  echo "[INFO] Generating matugen theme from wallpaper"
  # --source-color-index skips matugen's interactive color-picker prompt,
  # which reads /dev/tty and fails without a controlling terminal.
  if matugen image "$src" -t scheme-smart &> "$CACHE/matugen.log"; then
    echo "[INFO] matugen theme applied"
  else
    echo "[ERROR] matugen failed, see $CACHE/matugen.log"
    return 1
  fi
}

# One swaybg instance for every output in $1 (a JSON object output->image).
apply_swaybg() {
  local map="$1" args=() out img count=0
  while IFS=$'\t' read -r out img; do
    img=$(strip_url "$img")
    if [[ -n "$out" && -n "$img" && -f "$img" ]]; then
      args+=(-o "$out" -i "$img" -m fill)
      ((++count))
    elif [[ -n "$out" ]]; then
      echo "[WARN] skipping $out (missing file: $img)"
    fi
  done < <(echo "$map" | jq -r 'to_entries[] | "\(.key)\t\(.value)"')
  pkill -x swaybg 2>/dev/null || true
  if ((${#args[@]})); then
    nohup swaybg "${args[@]}" &>/dev/null & disown
    echo "[INFO] swaybg restarted for $count output(s)"
  else
    echo "[INFO] no wallpapers configured, swaybg stopped"
  fi
}

case "${1:-restore}" in
  apply)
    apply_swaybg "${2:-{}}"
    [[ -n "${3:-}" ]] && retheme "$3" || true
    ;;
  retheme)
    retheme "${2:?retheme needs an image path}"
    ;;
  restore)
    if [[ -f "$CONFIG" ]]; then
      apply_swaybg "$(jq -c '.wallpapersByOutput // {}' "$CONFIG")"
    else
      echo "[INFO] no $CONFIG yet, nothing to restore"
    fi
    ;;
  *)
    echo "usage: wallpaper.sh {apply '<json>' [image]|retheme <image>|restore}" >&2
    exit 2
    ;;
esac
