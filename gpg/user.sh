#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

gpg --list-secret-keys

if [[ ! -f "$GPG_KEY" ]]; then
  gpg --list-secret-keys | grep -q uid || echo "GPG key at \"$GPG_KEY\" path not found. GPG key will not be installed"
  exit 0
fi

gpg --import "$GPG_KEY"

