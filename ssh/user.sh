#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")
SELF_PATH=$(realpath "$(dirname "$0")")

mkdir --parents ~/.ssh
touch ~/.ssh/environment

if gpg --list-secret-keys | grep --quiet uid; then
  cd "$REPO_PATH" && git  secret reveal -f && cd -
  chmod 600 "$SELF_PATH"/keys/*
  for i in "$SELF_PATH"/keys/*id_rsa; do
    base=$(basename "$i")
    ln --symbolic --force "$i" ~/.ssh/"$base"
  done
fi

"$REPO_PATH/scripts/config_fish.sh" "$SELF_PATH"

