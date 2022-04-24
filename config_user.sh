#!/usr/bin/env bash

set -x

REPO_PATH=$(realpath "$(dirname "$0")")
echo $REPO_PATH

mkdir ~/.vim
mkdir ~/.vim/keymap
mkdir ~/.vim/bundle
mkdir ~/.docker
mkdir --parents ~/.local/bin
mkdir --parents ~/.local/share/fonts
mkdir ~/tmp

export PATH="$HOME/.local/bin:$PATH"

ln --symbolic "$REPO_PATH/vimrc" ~/.vimrc
ln --symbolic "$REPO_PATH/rnk-russian-qwerty.vim" ~/.vim/keymap/rnk-russian-qwerty.vim
ln --symbolic "$REPO_PATH/tmux.conf" ~/.tmux.conf
ln --symbolic "$REPO_PATH/gitconfig" ~/.gitconfig
ln --symbolic "$REPO_PATH/coc-settings.json" ~/.vim/coc-settings.json
cat "$REPO_PATH/docker_config.json" >> ~/.docker/config.json # Do not create symbolic because it might be populated with docker credentials

cat "$REPO_PATH/bashrc" >> ~/.bashrc

curl --location install-node.vercel.app/lts | bash -s -- --yes --prefix=$HOME/.local
curl --fail --location --output ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

vim  -c PlugInstall -c qall
COC_EXTENSIONS=$(cat vimrc | grep -oP "let g:coc_global_extensions \+= \['\K[\w\d-]+(?='\])" | awk 'BEGIN { ORS = " " } { print }')
vim -c "CocInstall -sync $COC_EXTENSIONS" -c qall
# vim -c "CocCommand clangd.install" -c qall tmp.cpp


wget --output-document ~/tmp/FiraCode.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/FiraCode.zip
unzip ~/tmp/FiraCode.zip -d ~/tmp/FiraCode
mv ~/tmp/FiraCode/*.otf ~/.local/share/fonts
# fc-cache -f -v

# xfce4 terminal:
#mkdir --parents ~/.local/share/xfce4/terminal/colorschemes
#cp onehalf/xfce4-terminal/OneHalfDark.theme ~/.local/share/xfce4/terminal/colorschemes/
#cp onehalf/xfce4-terminal/OneHalfLight.theme ~/.local/share/xfce4/terminal/colorschemes

#imwheel --kill --buttons "4 5"
#imwheel --kill --quit

# Hack for git on windows:
#git config --system core.sshCommand C:/Windows/System32/OpenSSH/ssh.exe

