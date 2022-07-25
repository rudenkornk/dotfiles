#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

wget https://github.com/neovim/neovim/releases/download/v0.7.2/nvim-linux64.deb

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install --yes --allow-downgrades --no-install-recommends \
  ./nvim-linux64.deb \
  bibclean \
  vim \

rm nvim-linux64.deb

gem install neovim
