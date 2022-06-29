#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

mkdir --parents ~/.local/bin

ln --symbolic --force "$REPO_PATH/bash/inputrc" ~/.inputrc

echo "source $REPO_PATH/bash/bashrc" > source_bashrc
begin="# --- dotfiles bash begin --- #"
end="# --- dotfiles bash end --- #"
"$REPO_PATH/scripts/insert_text.sh" source_bashrc ~/.bashrc "$begin" "$end"
rm source_bashrc

