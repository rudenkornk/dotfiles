#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

bash_source="$1"
component=$(basename $(realpath $bash_source))

echo "source $bash_source/bashrc" > source_bashrc
begin="# --- dotfiles $component begin --- #"
end="# --- dotfiles $component end --- #"
"$REPO_PATH/scripts/insert_text.sh" source_bashrc ~/.bashrc "$begin" "$end"
rm source_bashrc

