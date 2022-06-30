#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

fish_source="$1"
component=$(basename $(realpath $fish_source))

if [[ -d "$fish_source/fish_functions" ]]; then
  mkdir --parents ~/.config/fish/functions/
  for i in "$fish_source/fish_functions"/* ; do
    f=$(basename "$i")
    ln --symbolic --force "$i" ~/.config/fish/functions/$f
  done
fi
if [[ -f "$fish_source/$component.fish" ]]; then
  mkdir --parents ~/.config/fish/conf.d/
  ln --symbolic --force "$fish_source/$component.fish" ~/.config/fish/conf.d/$component.fish
fi

