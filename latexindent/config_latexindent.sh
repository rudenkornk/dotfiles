#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

# latexindent support for ubuntu < 22.04
mkdir --parents ~/.local/bin
UBUNTU_VERSION=$(lsb_release -d | grep --only-matching --perl-regexp "[\d\.]+")
if ! { echo "22.04"; echo "$UBUNTU_VERSION"; } | \
  sort --version-sort --check &> /dev/null; then
  wget https://github.com/cmhughes/latexindent.pl/releases/download/V3.17.2/latexindent.zip
  unzip latexindent.zip
  mv "latexindent/latexindent.pl" ~/.local/bin/
  mv "latexindent/defaultSettings.yaml" ~/.local/bin/
  mv "latexindent/LatexIndent" ~/.local/bin/
  ln --symbolic ~/.local/bin/latexindent.pl ~/.local/bin/latexindent
  rm "latexindent.zip"
  rm --recursive --force "latexindent"
fi

