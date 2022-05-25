#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")
IS_WSL=$(uname -a | grep --quiet WSL && echo true || echo false)

DNS=8.8.8.8
RESOLV_CONF=/etc/resolv.conf
if ! grep $DNS $RESOLV_CONF --quiet; then
  echo nameserver $DNS >> $RESOLV_CONF
fi

WSL_CONF=/etc/wsl.conf
if [[ $IS_WSL == "true" && ((-f $WSL_CONF && ! -s $WSL_CONF) || ! -f $WSL_CONF) ]]; then
  ln --symbolic --force "$REPO_PATH/wsl/wsl.conf" $WSL_CONF
fi

