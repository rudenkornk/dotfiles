#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

# Command line utils (those, which do not modify any files)

wget https://github.com/sharkdp/fd/releases/download/v8.4.0/fd-musl_8.4.0_amd64.deb --output-document fd.deb
wget https://github.com/sharkdp/bat/releases/download/v0.21.0/bat-musl_0.21.0_amd64.deb --output-document bat.deb
chmod 777 fd.deb
chmod 777 bat.deb
DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
  ./bat.deb \
  ./fd.deb \
  moreutils `# for ifne tool` \
  ripgrep \

rm fd.deb
rm bat.deb

