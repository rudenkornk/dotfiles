#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")
SELF_PATH=$(realpath "$(dirname "$0")")

mkdir --parents ~/.config/nvim
mkdir --parents ~/.config/nvim/keymap
mkdir --parents ~/.local/
export PATH="$HOME/.local/bin:$PATH"


pip2 install pynvim
pip2 install pypi

pip3 install jedi
pip3 install px
pip3 install pynvim
pip3 install pypi
pip3 install sympy

npm install --location=global neovim

# Link configs
ln --symbolic --force "$SELF_PATH/init.lua" ~/.config/nvim/init.lua
ln --symbolic --force "$REPO_PATH/keyboard_layouts/rnk-russian-qwerty.vim" ~/.config/nvim/keymap/rnk-russian-qwerty.vim
ln --symbolic --force "$SELF_PATH/coc-settings.json" ~/.config/nvim/coc-settings.json
ln --symbolic --force "$SELF_PATH/ftplugin" ~/.config/nvim/ftplugin; rm --force "$SELF_PATH/ftplugin/ftplugin"
ln --symbolic --force "$SELF_PATH/ftdetect" ~/.config/nvim/ftdetect; rm --force "$SELF_PATH/ftdetect/ftdetect"
ln --symbolic --force "$REPO_PATH/ultisnips" ~/.config/nvim/UltiSnips; rm --force "$REPO_PATH/ultisnips/ultisnips"

if [[ ! -d "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim" ]]; then
  # Install vim-plug
  sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
           https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
fi
nvim -c PlugInstall -c qall

# Install coc-nvim extensions
COC_EXTENSIONS=$(cat "$SELF_PATH/init.lua" | grep --only-matching --perl-regexp "let g:coc_global_extensions \+= \['\K[\w\d-]+(?='\])" | awk 'BEGIN { ORS = " " } { print }')
nvim -c "CocInstall -sync $COC_EXTENSIONS" -c quitall
# nvim -c "CocCommand clangd.install" -c qall tmp.cpp

nvim --headless -c UpdateRemotePlugins -c quitall

"$REPO_PATH/scripts/config_bash.sh" "$SELF_PATH"
"$REPO_PATH/scripts/config_fish.sh" "$SELF_PATH"

"$SELF_PATH/checkhealth.sh"
