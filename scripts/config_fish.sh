#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

fish_source="$1"
component=$(basename $(realpath $fish_source))

key_bindings_file=~/.config/fish/functions/fish_user_key_bindings.fish
if [[ ! -f $key_bindings_file ]]; then
  mkdir --parents ~/.config/fish/functions/
  echo "function fish_user_key_bindings" >> $key_bindings_file
  echo "end" >> $key_bindings_file
fi

if [[ -d $fish_source/fish_functions ]]; then
  for i in "$fish_source/fish_functions"/* ; do
    f=$(basename "$i")
    ln --symbolic --force "$i" ~/.config/fish/functions/$f
  done
fi
if [[ -f $fish_source/$component.fish ]]; then
  mkdir --parents ~/.config/fish/conf.d/
  ln --symbolic --force "$fish_source/$component.fish" ~/.config/fish/conf.d/$component.fish
fi

if [[ -f $fish_source/key_bindings.fish ]]; then
  target_file=$key_bindings_file
  insert_before=$(grep --line-number "fish_user_key_bindings" $target_file | cut --delimiter ":" --fields 1)
  insert_before=$((insert_before + 1))
  begin="# --- dotfiles $component begin --- #"
  end="# --- dotfiles $component end --- #"
  "$REPO_PATH/scripts/insert_text.sh" $fish_source/key_bindings.fish $target_file "$begin" "$end" $insert_before
fi


