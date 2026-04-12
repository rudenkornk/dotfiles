#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

shopt -s nullglob

# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

main() {
  echo -n "  "
  df / --block-size G | awk 'NR==2 {printf "%.1fTiB/%.1fTiB  ", $3 / 1024, $2 / 1024}'

  echo -n "  "
  if [[ "${XDG_CURRENT_DESKTOP,,}" == *"gnome"* ]]; then
    gsettings get org.gnome.desktop.input-sources mru-sources | python3 -c "import sys, ast; print(ast.literal_eval(sys.stdin.read())[0][1])"
  elif [[ "${XDG_CURRENT_DESKTOP,,}" == *"niri"* || -v NIRI_SOCKET ]]; then
    niri msg -j keyboard-layouts | jq -r '.names[.current_idx] | .[0:2] | ascii_downcase'
  else
    localectl status | grep -oP "X11 Layout:\s*\K.*"
  fi

  sleep 0.1
}

# run main driver
main
