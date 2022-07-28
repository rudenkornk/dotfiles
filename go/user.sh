#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")
SELF_PATH=$(realpath "$(dirname "$0")")

mkdir --parents ~/.local
wget https://go.dev/dl/go1.18.3.linux-amd64.tar.gz --output-document go.tar.gz
if [[ -f ~/.local/go ]]; then
  chmod -R +w ~/.local/go
  rm -rf ~/.local/go
fi
tar -C ~/.local -xzf go.tar.gz
rm go.tar.gz

"$REPO_PATH/scripts/config_fish.sh" "$SELF_PATH"
