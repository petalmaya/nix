#!/usr/bin/env bash
set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
config_file="$config_dir/fuzzel/fuzzel.ini"
# Use XDG tilde form so the include stays portable across HM rebuilds
if [[ "$config_dir" == "$HOME"/* ]]; then
  include_dir="~/${config_dir#"$HOME"/}"
else
  include_dir="$config_dir"
fi
include_line="include=$include_dir/fuzzel/themes/generated"

mkdir -p "$(dirname "$config_file")"
mkdir -p "$config_dir/fuzzel/themes"

write_if_changed() {
  local target="$1" tmp="$2"
  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    mv "$tmp" "$target"
    return
  fi
  if ! cmp -s "$target" "$tmp"; then
    cat "$tmp" >"$target"
  fi
  rm -f "$tmp"
}

if [ ! -f "$config_file" ]; then
  printf '%s\n' "$include_line" >"$config_file"
elif grep -qF "$include_line" "$config_file"; then
  :
elif grep -q '^include=.*themes' "$config_file"; then
  tmp_file="$(mktemp "${config_file}.tmp.XXXXXX")"
  trap 'rm -f "$tmp_file"' EXIT
  sed 's|^include=.*themes.*|'"$include_line"'|' "$config_file" >"$tmp_file"
  trap - EXIT
  write_if_changed "$config_file" "$tmp_file"
else
  [ -s "$config_file" ] && [ -n "$(tail -c1 "$config_file" 2>/dev/null)" ] && echo >>"$config_file"
  printf '%s\n' "$include_line" >>"$config_file"
fi

# fuzzel has no reload signal; next launch picks up the new theme.
