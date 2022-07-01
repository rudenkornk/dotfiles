#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")
SELF_PATH=$(realpath "$(dirname "$0")")

export PATH="$HOME/.local/bin:$PATH"
nvim --headless -c "checkhealth" -c "w health" -c quitall

rm health
