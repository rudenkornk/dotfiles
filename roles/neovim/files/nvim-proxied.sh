#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

encrypted_proxy=~/.config/dotfiles-proxy/proxy.sh.sops
proxy=~/.local/tmp/proxy.sh

# TODO: make this transient with some sort of tmpfs.
# Decrypting this every time is slow.
if [[ ! -f $proxy ]]; then
  mkdir -p "$(dirname "$proxy")"
  touch $proxy && chmod 600 $proxy
  sops --decrypt $encrypted_proxy >$proxy || true
fi

if [[ -f $proxy ]]; then
  # shellcheck source=/dev/null
  source $proxy
fi

~/.local/nvim-linux-"$(uname --machine)"/bin/nvim "$@"
