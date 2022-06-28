#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

mkdir --parents ~/.local/bin

ln --symbolic --force "$REPO_PATH/bash/inputrc" ~/.inputrc

begin="# --- dotfiles bash begin --- #"
end="# --- dotfiles bash end --- #"
"$REPO_PATH/scripts/insert_text.sh" "$REPO_PATH/bash/bashrc" ~/.bashrc "$begin" "$end"

