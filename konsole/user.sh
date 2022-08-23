#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")
SELF_PATH=$(realpath "$(dirname "$0")")

mkdir --parents ~/.local/share/konsole/
mkdir --parents ~/.config

konsolerc=~/.config/konsolerc
if [[ ! -f ~/.config/konsolerc ]]; then
  echo "[Desktop Entry]" >> $konsolerc
  echo "DefaultProfile=Main.profile" >> $konsolerc
else
  sed -i 's/DefaultProfile=.*/DefaultProfile=Main.profile/' $konsolerc
fi

ln --symbolic --force "$SELF_PATH/Main.profile" ~/.local/share/konsole/Main.profile

"$REPO_PATH/scripts/config_fish.sh" "$SELF_PATH"

