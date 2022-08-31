#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")
SELF_PATH=$(realpath "$(dirname "$0")")

mkdir --parents ~/.config/fish

mkdir --parents ~/.config/fish/functions
# Unlink fish_plugins, so that fisher will not overrite it
rm --force ~/.config/fish/fish_plugins
fish --command "curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher"
ln --symbolic --force "$SELF_PATH/fish_plugins" ~/.config/fish/fish_plugins
fish --command "fisher update"

# Configure tide prompt
fish --command "echo 1 1 1 2 2 2 1 2 y | tide configure"

"$REPO_PATH/scripts/config_fish.sh" "$SELF_PATH"

#chsh --shell /usr/bin/fish
