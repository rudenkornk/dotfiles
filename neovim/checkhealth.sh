#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")
SELF_PATH=$(realpath "$(dirname "$0")")

export PATH="$HOME/.local/bin:$PATH"

for component in \
                 coc \
                 nvim-treesitter \
                 provider \
                 ; do
  nvim --headless -c "checkhealth $component" -c "w ${component}_health" -c quitall
  ! grep --quiet ERROR ${component}_health
  rm ${component}_health
done

