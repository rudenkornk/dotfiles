#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

ln --symbolic "$REPO_PATH/git/gitconfig" ~/.gitconfig

npm install --global git-run

# gr tag discover

