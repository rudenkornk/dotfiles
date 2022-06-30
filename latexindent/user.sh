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
  unzip latexindent.zip -d tmp
  mv --force "tmp/latexindent/latexindent.pl" ~/.local/bin/
  mv --force "tmp/latexindent/defaultSettings.yaml" ~/.local/bin/
  if [[ -d ~/.local/bin/LatexIndent ]]; then
    rm --recursive --force ~/.local/bin/LatexIndent
  fi
  mv --force "tmp/latexindent/LatexIndent" ~/.local/bin/
  ln --symbolic --force ~/.local/bin/latexindent.pl ~/.local/bin/latexindent
  rm "latexindent.zip"
  rm --recursive --force "tmp"
fi

