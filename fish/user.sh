#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")
SELF_PATH=$(realpath "$(dirname "$0")")

mkdir --parents ~/.config/fish
ln --symbolic --force "$SELF_PATH/fish_plugins" ~/.config/fish/fish_plugins

mkdir --parents ~/.config/fish/functions
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish &> ~/.config/fish/functions/fisher.fish
fish --command "fisher update"

# Configure tide prompt
fish --command "echo 1 1 1 2 2 2 1 2 y | tide configure"

"$REPO_PATH/scripts/config_fish.sh" "$SELF_PATH"

