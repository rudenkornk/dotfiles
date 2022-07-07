#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")
SELF_PATH=$(realpath "$(dirname "$0")")

ln --symbolic --force "$SELF_PATH/gitconfig" ~/.gitconfig

export PATH="$HOME/.local/bin:$PATH"
npm install --location=global --no-audit git-run
# gr tag discover

"$REPO_PATH/scripts/config_fish.sh" "$SELF_PATH"

