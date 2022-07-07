#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")
SELF_PATH=$(realpath "$(dirname "$0")")

export PATH="$HOME/.local/bin:$PATH"

if ! tmux -V; then
  wget https://github.com/tmux/tmux/releases/download/3.3a/tmux-3.3a.tar.gz --output-document tmux.tar.gz
  tar -zxf tmux.tar.gz
  cd tmux-3*/
  ./configure --prefix $HOME/.local/tmux
  make && make install
  cd -
  rm tmux.tar.gz
  rm --recursive --force tmux-3*
fi

ln --symbolic --force "$SELF_PATH/tmux.conf" ~/.tmux.conf
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# For tmux-window-name
pip3 install libtmux

"$REPO_PATH/scripts/config_fish.sh" "$SELF_PATH"

# <prefix>I

# Some special processing is needed for tmux-yank on wayland, see
# https://github.com/tmux-plugins/tmux-yank

