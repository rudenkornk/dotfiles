#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

REPO_PATH=$(realpath "$(dirname "$0")/..")
SELF_PATH=$(realpath "$(dirname "$0")")


# Preconfigured Configuration notes:
# LunarVim --- too slow, about 400ms to start
# nvoid --- unpopular compared to others, otherwise looking ok
# NvChad --- looks ok
# AstroNvim --- looks ok, though wants strange dependencies like htop and lazygit
# CosmicNvim --- looks ok; no whichkey plugin?
# nyoom.nvim --- weird configuration language instead of pure lua

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/go/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

go install github.com/rhysd/actionlint/cmd/actionlint@latest

pip2 install --user pynvim
pip2 install --user pypi

pip3 install --user autopep8
pip3 install --user px
pip3 install --user pynvim
pip3 install --user pypi
pip3 install --user sympy

npm list --location=global alex || npm install --location=global alex
npm list --location=global neovim || npm install --location=global neovim

if [[ ! -d ~/.config/nvim ]]; then
  git clone https://github.com/NvChad/NvChad ~/.config/nvim
  git --git-dir=$HOME/.config/nvim/.git --work-tree=$HOME/.config/nvim checkout \
    45f3a0e32da3890d0e2d06e53cb002aa99c6ab76
fi

mkdir --parents ~/.config/nvim/keymap
ln --symbolic --force "$REPO_PATH/keyboard_layouts/rnk-russian-qwerty.vim" ~/.config/nvim/keymap/rnk-russian-qwerty.vim

rm --force ~/.config/nvim/lua/custom
ln --symbolic --force "$SELF_PATH/nvchad" ~/.config/nvim/lua/custom

mkdir --parents ~/.local/share/nvim/site/pack/packer/opt/ui
mkdir --parents ~/.local/share/nvim/site/pack/packer/opt/extensions
# TODO
# Also, please see https://github.com/zbirenbaum/copilot.lua#preliminary-steps
#nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'
#nvim --headless -c 'MasonInstallAll'

"$REPO_PATH/scripts/config_fish.sh" "$SELF_PATH"

"$SELF_PATH/checkhealth.sh"
