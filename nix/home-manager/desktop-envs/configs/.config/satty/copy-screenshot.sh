#!/usr/bin/env bash
set -euo pipefail

directory="$HOME/Downloads/screenshots"
mkdir -p "$directory"
temporary=$(mktemp "$directory/.screenshot.XXXXXX")
trap 'rm -f -- "$temporary"' EXIT
cat >"$temporary"

wl-copy <"$temporary" || notify-send --urgency=critical "Screenshot clipboard copy failed" || true

exec {lock}>"$directory/.rotation.lock"
flock "$lock"

for ((index = 5; index >= 1; index--)); do
  source="$directory/latest-$((index - 1)).png"
  if ((index == 1)); then
    source="$directory/latest.png"
  fi
  if [[ -f "$source" ]]; then
    mv -- "$source" "$directory/latest-$index.png"
  fi
done

mv -- "$temporary" "$directory/latest.png"
