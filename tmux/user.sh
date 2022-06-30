#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")
SELF_PATH=$(realpath "$(dirname "$0")")

ln --symbolic --force "$SELF_PATH/tmux.conf" ~/.tmux.conf
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

"$REPO_PATH/scripts/config_bash.sh" "$SELF_PATH"

# <prefix>I

# Some special processing is needed for tmux-yank on wayland, see
# https://github.com/tmux-plugins/tmux-yank

