#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")
SELF_PATH=$(realpath "$(dirname "$0")")

mkdir --parents ~/.local/bin

ln --symbolic --force "$SELF_PATH/inputrc" ~/.inputrc

"$REPO_PATH/scripts/config_bash.sh" "$SELF_PATH"
