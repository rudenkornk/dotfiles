#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

bash_source="$1"
component=$(basename $(realpath $bash_source))

begin="# --- dotfiles $component begin --- #"
end="# --- dotfiles $component end --- #"
"$REPO_PATH/scripts/insert_text.sh" "$bash_source/bashrc" ~/.bashrc "$begin" "$end"

