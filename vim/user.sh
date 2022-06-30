#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")
SELF_PATH=$(realpath "$(dirname "$0")")

mkdir --parents ~/.vim
mkdir --parents ~/.vim/keymap
mkdir --parents ~/.config/coc
mkdir --parents ~/.local/
export PATH="$HOME/.local/bin:$PATH"

# Link configs
ln --symbolic --force "$SELF_PATH/vimrc" ~/.vimrc
ln --symbolic --force "$REPO_PATH/keyboard_layouts/rnk-russian-qwerty.vim" ~/.vim/keymap/rnk-russian-qwerty.vim
ln --symbolic --force "$SELF_PATH/coc-settings.json" ~/.vim/coc-settings.json
ln --symbolic --force "$SELF_PATH/ftplugin" ~/.vim/ftplugin; rm --force "$SELF_PATH/ftplugin/ftplugin"
ln --symbolic --force "$SELF_PATH/ftdetect" ~/.vim/ftdetect; rm --force "$SELF_PATH/ftdetect/ftdetect"
ln --symbolic --force "$SELF_PATH/ultisnips" ~/.config/coc/ultisnips; rm --force "$SELF_PATH/ultisnips/ultisnips"

if [[ ! -d ~/.vim/autoload/plug.vim ]]; then
  # Install vim-plug
  curl --fail --location --output ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi
vim  -c PlugInstall -c qall

# Install coc-nvim extensions
COC_EXTENSIONS=$(cat "$REPO_PATH/vim/vimrc" | grep --only-matching --perl-regexp "let g:coc_global_extensions \+= \['\K[\w\d-]+(?='\])" | awk 'BEGIN { ORS = " " } { print }')
vim -c "CocInstall -sync $COC_EXTENSIONS" -c qall
# vim -c "CocCommand clangd.install" -c qall tmp.cpp

pip3 install px
pip3 install jedi
pip3 install sympy

"$REPO_PATH/scripts/config_bash.sh" "$SELF_PATH"

