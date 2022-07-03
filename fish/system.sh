#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

apt-add-repository ppa:fish-shell/release-3 --yes
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
  fish \

chsh --shell /usr/bin/fish
