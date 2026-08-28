#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

shopt -s nullglob

# Setting the locale; some users have issues with different locales, this forces the correct one.
export LC_ALL=en_US.UTF-8

display_keyboard_layout() {
  echo -n "  "
  if [[ "${XDG_CURRENT_DESKTOP,,}" == *"gnome"* ]]; then
    gsettings get org.gnome.desktop.input-sources mru-sources | python3 -c "import sys, ast; print(ast.literal_eval(sys.stdin.read())[0][1])"
  elif [[ "${XDG_CURRENT_DESKTOP,,}" == *"niri"* || -v NIRI_SOCKET ]]; then
    niri msg -j keyboard-layouts | jq -r '.names[.current_idx] | .[0:2] | ascii_downcase'
  else
    localectl status | grep -oP "X11 Layout:\s*\K.*"
  fi
}

main() {
  short=false

  echo -n " "
  if [ "$short" = true ]; then
    df /home --block-size G | awk 'NR==2 {printf "%.1fT", $3 / 1024}'
  else
    df /home --block-size G | awk 'NR==2 {printf "%.1fTiB/%.1fTiB  ", $3 / 1024, $2 / 1024}'
  fi

  # display_keyboard_layout

  sleep 0.1
}

# Run main driver.
main
