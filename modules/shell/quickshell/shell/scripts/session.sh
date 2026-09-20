#!/usr/bin/env bash
set -u
dir="${1:-}"
[ -n "$dir" ] && [ -d "$dir" ] || exit 0
find "$dir" -maxdepth 1 -name '*.desktop' -print0 | while IFS= read -r -d '' f; do
  grep -qiE '^(Hidden|NoDisplay)=true' "$f" && continue
  name=$(sed -n 's/^Name=\(.*\)/\1/p' "$f" | head -n 1)
  exec=$(sed -n 's/^Exec=\(.*\)/\1/p' "$f" | head -n 1)
  [ -n "$name" ] && [ -n "$exec" ] || continue
  printf '%s\t%s\n' "$name" "$exec"
done
