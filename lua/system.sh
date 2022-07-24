#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
  liblua5.3-dev \
  lua5.3 \

wget https://luarocks.org/releases/luarocks-3.9.1.tar.gz --output-document luarocks.tar.gz
tar zxpf luarocks.tar.gz
cd luarocks-3.9.1
./configure && make && make install

cd -
rm --recursive --force luarocks-3.9.1
rm luarocks.tar.gz

