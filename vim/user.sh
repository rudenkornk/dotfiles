#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")

mkdir ~/.vim
mkdir ~/.vim/keymap
mkdir --parents ~/.config/coc
mkdir --parents ~/.local/
export PATH="$HOME/.local/bin:$PATH"

# Link configs
ln --symbolic "$REPO_PATH/vim/vimrc" ~/.vimrc
ln --symbolic "$REPO_PATH/keyboard_layouts/rnk-russian-qwerty.vim" ~/.vim/keymap/rnk-russian-qwerty.vim
ln --symbolic "$REPO_PATH/vim/coc-settings.json" ~/.vim/coc-settings.json
ln --symbolic "$REPO_PATH/vim/ftplugin" ftplugin; mv ftplugin ~/.vim/
ln --symbolic "$REPO_PATH/vim/ftdetect" ftdetect; mv ftdetect ~/.vim/
ln --symbolic "$REPO_PATH/vim/ultisnips" ultisnips; mv ultisnips ~/.config/coc/

# Install vim-plug
curl --fail --location --output ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim  -c PlugInstall -c qall

# Install coc-nvim extensions
COC_EXTENSIONS=$(cat "$REPO_PATH/vim/vimrc" | grep --only-matching --perl-regexp "let g:coc_global_extensions \+= \['\K[\w\d-]+(?='\])" | awk 'BEGIN { ORS = " " } { print }')
vim -c "CocInstall -sync $COC_EXTENSIONS" -c qall
# vim -c "CocCommand clangd.install" -c qall tmp.cpp

pip3 install px
pip3 install jedi
pip3 install sympy

