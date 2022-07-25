#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

mkdir --parents ~/.local/share/fonts

# Install FiraCode
wget --output-document "FiraCode.zip" \
  https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/FiraCode.zip
unzip "FiraCode.zip" -d "FiraCode"
mv "FiraCode/"*.otf ~/.local/share/fonts
rm "FiraCode.zip"
rm "FiraCode/"*
rmdir "FiraCode"
fc-cache -f -v

