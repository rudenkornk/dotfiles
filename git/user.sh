#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

ln --symbolic --force "$REPO_PATH/git/gitconfig" ~/.gitconfig

npm install --global --no-audit git-run
# gr tag discover

echo "source $REPO_PATH/git/bashrc" > source_bashrc
begin="# --- dotfiles git begin --- #"
end="# --- dotfiles git end --- #"
"$REPO_PATH/scripts/insert_text.sh" source_bashrc ~/.bashrc "$begin" "$end"
rm source_bashrc
