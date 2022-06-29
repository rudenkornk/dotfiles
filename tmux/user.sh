#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

ln --symbolic --force "$REPO_PATH/tmux/tmux.conf" ~/.tmux.conf
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

echo "source $REPO_PATH/tmux/bashrc" > source_bashrc
begin="# --- dotfiles tmux begin --- #"
end="# --- dotfiles tmux end --- #"
"$REPO_PATH/scripts/insert_text.sh" source_bashrc ~/.bashrc "$begin" "$end"
rm source_bashrc

# <prefix>I

# Some special processing is needed for tmux-yank on wayland, see
# https://github.com/tmux-plugins/tmux-yank

