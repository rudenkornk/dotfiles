#!/usr/bin/env bash

set -x

if [[ -z "$BUILD_PATH" ]]; then
  echo "Please set BUILD_PATH var"
  exit 1
fi

UBUNTU_VERSION=$(lsb_release -d | grep --only-matching --perl-regexp "[\d\.]+")
REPO_PATH=$(realpath "$(dirname "$0")/..")
echo $REPO_PATH

mkdir ~/.vim
mkdir ~/.vim/keymap
mkdir ~/.docker
mkdir --parents ~/.local/bin
mkdir --parents ~/.local/share/fonts
mkdir --parents ~/.config/coc
mkdir --parents "$BUILD_PATH"

export PATH="$HOME/.local/bin:$PATH"

ln --symbolic "$REPO_PATH/vim/vimrc" ~/.vimrc
ln --symbolic "$REPO_PATH/keyboard_layouts/rnk-russian-qwerty.vim" ~/.vim/keymap/rnk-russian-qwerty.vim
ln --symbolic "$REPO_PATH/tmux.conf" ~/.tmux.conf
ln --symbolic "$REPO_PATH/gitconfig" ~/.gitconfig
ln --symbolic "$REPO_PATH/vim/coc-settings.json" ~/.vim/coc-settings.json
ln --symbolic "$REPO_PATH/vim/ftplugin" ftplugin; mv ftplugin ~/.vim/
ln --symbolic "$REPO_PATH/vim/ftdetect" ftdetect; mv ftdetect ~/.vim/
ln --symbolic "$REPO_PATH/vim/ultisnips" ultisnips; mv ultisnips ~/.config/coc/
cat "$REPO_PATH/docker_config.json" >> ~/.docker/config.json # Do not create symbolic because it might be populated with docker credentials

#ln --symbolic "$REPO_PATH/inputrc" ~/.inputrc
cat "$REPO_PATH/bashrc" >> ~/.bashrc

curl --location install-node.vercel.app/lts | bash -s -- --yes --prefix=$HOME/.local
curl --fail --location --output ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

vim  -c PlugInstall -c qall
COC_EXTENSIONS=$(cat vimrc | grep --only-matching --perl-regexp "let g:coc_global_extensions \+= \['\K[\w\d-]+(?='\])" | awk 'BEGIN { ORS = " " } { print }')
vim -c "CocInstall -sync $COC_EXTENSIONS" -c qall
# vim -c "CocCommand clangd.install" -c qall tmp.cpp
wget --output-document="$BUILD_PATH/ltex-ls.tar.gz"
  https://github.com/valentjn/ltex-ls/releases/download/15.2.0/ltex-ls-15.2.0-linux-x64.tar.gz
tar -xvzf --directory "$BUILD_PATH" ltex-ls-*
rm "$BUILD_PATH/ltex-ls-*.tar.gz"
mv "$BUILD_PATH/ltex-ls-*" ~/.config/coc/extensions/node_modules/coc-ltex/lib/
if ! { echo "22.04"; echo "$UBUNTU_VERSION"; } | \
  sort --version-sort --check &> /dev/null; then
  wget --output-document "$BUILD_PATH/latexindent.zip"
    https://github.com/cmhughes/latexindent.pl/releases/download/V3.17.2/latexindent.zip
  unzip -d "$BUILD_PATH" latexindent.zip
  mv "$BUILD_PATH/latexindent/latexindent.pl" ~/.local/bin/
  mv "$BUILD_PATH/latexindent/defaultSettings.yaml" ~/.local/bin/
  mv "$BUILD_PATH/latexindent/LatexIndent" ~/.local/bin/
  ln --symbolic ~/.local/bin/latexindent.pl ~/.local/bin/latexindent
  rm "$BUILD_PATH/latexindent.zip"
  rm -rf "$BUILD_PATH/latexindent"
fi


newgrp docker

pip3 install px
pip3 install jedi

if false; then
  wget --output-document "$BUILD_PATH/FiraCode.zip" \
    https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/FiraCode.zip
  unzip "$BUILD_PATH/FiraCode.zip" -d "$BUILD_PATH/FiraCode"
  mv "$BUILD_PATH/FiraCode/"*.otf ~/.local/share/fonts
  rm "$BUILD_PATH/FiraCode.zip"
  rm "$BUILD_PATH/FiraCode/"*
  rmdir "$BUILD_PATH/FiraCode"
  # fc-cache -f -v
fi

# xfce4 terminal:
#mkdir --parents ~/.local/share/xfce4/terminal/colorschemes
#cp onehalf/xfce4-terminal/OneHalfDark.theme ~/.local/share/xfce4/terminal/colorschemes/
#cp onehalf/xfce4-terminal/OneHalfLight.theme ~/.local/share/xfce4/terminal/colorschemes

#imwheel --kill --buttons "4 5"
#imwheel --kill --quit

# Hack for git on windows:
#git config --system core.sshCommand C:/Windows/System32/OpenSSH/ssh.exe

