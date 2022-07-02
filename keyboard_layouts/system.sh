#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")
SELF_PATH=$(realpath "$(dirname "$0")")

if [[ -d /usr/share/X11/xkb ]]; then
  ln --symbolic --force "$SELF_PATH/rnk" /usr/share/X11/xkb/symbols/rnk
  target_file=/usr/share/X11/xkb/rules/evdev.xml
  insert_before=$(grep --line-number "</layoutList>" $target_file \
    | cut --delimiter ":" --fields 1)
  begin="<!-- dotfiles begin -->"
  end="<!-- dotfiles end -->"
  "$REPO_PATH/scripts/insert_text.sh" "$SELF_PATH/evdev.xml" $target_file "$begin" "$end" $insert_before
  dpkg-reconfigure xkb-data
fi

