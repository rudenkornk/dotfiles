#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

mkdir --parents ~/.local/
export PATH="$HOME/.local/bin:$PATH"

curl --location install-node.vercel.app/lts | bash -s -- --yes --prefix=$HOME/.local/
