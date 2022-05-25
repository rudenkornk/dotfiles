#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

if [[ -d /usr/share/X11/xkb/symbols ]]; then
  ln -s "$REPO_PATH/keyboard_layouts/rnk" /usr/share/X11/xkb/symbols/rnk
fi
# Insert contents of evdev.xml into /usr/share/X11/xkb/rules/evdev.xml into appropriate place
# sudo dpkg-reconfigure xkb-data


