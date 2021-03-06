#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")
IS_WSL=$(uname --all | grep --quiet WSL && echo true || echo false)

if [[ $IS_WSL != "true" ]]; then
  exit
fi

WSL_CONF=/etc/wsl.conf
if [[ ((-f $WSL_CONF && ! -s $WSL_CONF) || ! -f $WSL_CONF) ]]; then
  ln --symbolic --force "$REPO_PATH/wsl/wsl.conf" $WSL_CONF
fi

#DNS=8.8.8.8
#RESOLV_CONF=/etc/resolv.conf
#if ! grep $DNS $RESOLV_CONF --quiet; then
#  echo nameserver $DNS >> $RESOLV_CONF
#fi
