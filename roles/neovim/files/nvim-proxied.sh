#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

proxy=~/.config/dotfiles-proxy/proxy.auth

if [[ -f $proxy ]]; then
  source $proxy
fi

~/.local/nvim-linux-"$(uname --machine)"/bin/nvim "$@"
