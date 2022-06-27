#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

ln --symbolic "$REPO_PATH/tmux/tmux.conf" ~/.tmux.conf
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

cat "$REPO_PATH/bash/bashrc" >> ~/.bashrc

# <prefix>I

# Some special processing is needed for tmux-yank on wayland, see
# https://github.com/tmux-plugins/tmux-yank

