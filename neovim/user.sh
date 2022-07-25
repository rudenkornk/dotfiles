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
go install mvdan.cc/sh/v3/cmd/shfmt@latest

cargo install stylua

pip2 install --user pynvim
pip2 install --user pypi

pip3 install --user autopep8
pip3 install --user cmakelang
pip3 install --user flake8
pip3 install --user jedi
pip3 install --user proselint
pip3 install --user px
pip3 install --user pydocstyle
pip3 install --user pynvim
pip3 install --user pypi
pip3 install --user sympy

npm list --location=global alex || npm install --location=global alex
npm list --location=global eslint_d || npm install --location=global eslint_d
npm list --location=global jsonlint || npm install --location=global jsonlint
npm list --location=global neovim || npm install --location=global neovim

if ! command -v hadolint &> /dev/null; then
  wget https://github.com/hadolint/hadolint/releases/download/v2.10.0/hadolint-Linux-x86_64 --output-document=hadolint
  chmod +x hadolint
  mv hadolint ~/.local/bin
fi

if [[ ! -d ~/.config/nvim ]]; then
  git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1
fi

mkdir --parents ~/.config/nvim/keymap
ln --symbolic --force "$REPO_PATH/keyboard_layouts/rnk-russian-qwerty.vim" ~/.config/nvim/keymap/rnk-russian-qwerty.vim

rm --force ~/.config/nvim/lua/custom
ln --symbolic --force "$SELF_PATH/nvchad" ~/.config/nvim/lua/custom

mkdir --parents ~/.local/share/nvim/site/pack/packer/opt/ui
mkdir --parents ~/.local/share/nvim/site/pack/packer/opt/extensions
nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

"$REPO_PATH/scripts/config_fish.sh" "$SELF_PATH"

"$SELF_PATH/checkhealth.sh"
