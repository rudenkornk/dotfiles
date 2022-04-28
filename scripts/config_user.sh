#!/usr/bin/env bash

set -x

REPO_PATH=$(realpath "$(dirname "$0")/..")
echo $REPO_PATH

mkdir ~/.vim
mkdir ~/.vim/keymap
mkdir ~/.vim/bundle
mkdir ~/.docker
mkdir --parents ~/.local/bin
mkdir --parents ~/.local/share/fonts

export PATH="$HOME/.local/bin:$PATH"

ln --symbolic "$REPO_PATH/vim/vimrc" ~/.vimrc
ln --symbolic "$REPO_PATH/keyboard_layouts/rnk-russian-qwerty.vim" ~/.vim/keymap/rnk-russian-qwerty.vim
ln --symbolic "$REPO_PATH/tmux.conf" ~/.tmux.conf
ln --symbolic "$REPO_PATH/gitconfig" ~/.gitconfig
ln --symbolic "$REPO_PATH/vim/coc-settings.json" ~/.vim/coc-settings.json
cat "$REPO_PATH/docker_config.json" >> ~/.docker/config.json # Do not create symbolic because it might be populated with docker credentials

cat "$REPO_PATH/bashrc" >> ~/.bashrc

curl --location install-node.vercel.app/lts | bash -s -- --yes --prefix=$HOME/.local
curl --fail --location --output ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

vim  -c PlugInstall -c qall
COC_EXTENSIONS=$(cat vimrc | grep --only-matching --perl-regexp "let g:coc_global_extensions \+= \['\K[\w\d-]+(?='\])" | awk 'BEGIN { ORS = " " } { print }')
vim -c "CocInstall -sync $COC_EXTENSIONS" -c qall
# vim -c "CocCommand clangd.install" -c qall tmp.cpp
wget https://github.com/valentjn/ltex-ls/releases/download/15.2.0/ltex-ls-15.2.0-linux-x64.tar.gz
tar -xvzf ltex-ls-*
mv ltex-ls-* ~/.config/coc/extensions/node_modules/coc-ltex/lib/
rm ltex-ls-*.tar.gz
ln --symbolic "$REPO_PATH/vim/ftplugin" ~/.vim/ftplugin


newgrp docker

wget --output-document FiraCode.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/FiraCode.zip
unzip FiraCode.zip -d FiraCode
mv FiraCode/*.otf ~/.local/share/fonts
rm FiraCode.zip
rm FiraCode/*
rmdir FiraCode
# fc-cache -f -v

# xfce4 terminal:
#mkdir --parents ~/.local/share/xfce4/terminal/colorschemes
#cp onehalf/xfce4-terminal/OneHalfDark.theme ~/.local/share/xfce4/terminal/colorschemes/
#cp onehalf/xfce4-terminal/OneHalfLight.theme ~/.local/share/xfce4/terminal/colorschemes

#imwheel --kill --buttons "4 5"
#imwheel --kill --quit

# Hack for git on windows:
#git config --system core.sshCommand C:/Windows/System32/OpenSSH/ssh.exe

