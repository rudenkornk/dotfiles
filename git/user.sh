#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")
SELF_PATH=$(realpath "$(dirname "$0")")

ln --symbolic --force "$SELF_PATH/gitconfig" ~/.gitconfig

npm install --global --no-audit git-run
# gr tag discover

"$REPO_PATH/scripts/config_bash.sh" "$SELF_PATH"

