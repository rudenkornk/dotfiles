# Dotfiles readme
Informal descripition, which should be rewritten as some setup script

Setup keyboard:
1. Copy rnk to /usr/share/X11/xkb/symbols
2. Insert contents of evdev.xml into /usr/share/X11/xkb/rules/evdev.xml into appropriate place
3. ln -s dotfiles/rnk-russian-qwerty.vim /usr/share/vim/vim*/keymap/rnk-russian-qwerty.vim
4. Use .vimrc file
5. sudo dpkg-reconfigure xkb-data


c++ dev:
sudo apt install clang clang-format clang-tidy


Install xsel package for tmux-yank
sudo apt install xsel

Install symlinks
ln -s dotfiles/vimrc .vimrc
ln -s dotfiles/tmux.conf .tmux.conf
ln -s dotfiles/gitconfig .gitconfig
ln -s dotfiles/coc-settings.json ~/.vim/coc-settings.json
sudo ln -s dotfiles/wsl.conf /etc/conf

sudo ln -s dotfiles/rnk /usr/share/X11/xkb/symbols/rnk

VIM plugins:

git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
:PluginInstall

YouCompleteMe:
cd ~/.vim/bundle/YouCompleteMe
./install.py --clangd-completer # --all

coc.nvim:
curl -sL install-node.vercel.app/lts | bash
git --git-dir=~/.vim/bundle/coc.nvim checkout release

Highlight:
needs compilation:
https://github.com/jeaye/color_coded
OR
https://github.com/bfrg/vim-cpp-modern

Download & install nerd fonts:
https://github.com/ryanoasis/nerd-fonts


bashrc:
stty erase '^?'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias tmux='tmux -2 -u'
export PS1="\[\e[1;32m\]${debian_chroot:+($debian_chroot)}\u@\h:\[\e[m\]\[\e[0;36m\]\w\\[\e[m\]$ "

if [ -z "$SSH_AUTH_SOCK" ] ; then
  eval "$(ssh-agent -s)" &> /dev/null
  ssh-add ~/.ssh/* &> /dev/null
fi

Hack for git on windows:
git config --system core.sshCommand C:/Windows/System32/OpenSSH/ssh.exe


xfce4 terminal:
mkdir --parents ~/.local/share/xfce4/terminal/colorschemes
cp onehalf/xfce4-terminal/OneHalfDark.theme ~/.local/share/xfce4/terminal/colorschemes/
cp onehalf/xfce4-terminal/OneHalfLight.theme ~/.local/share/xfce4/terminal/colorschemes

imwheel --kill --buttons "4 5"
imwheel --kill --quit
source /usr/share/bash-completion/completions/git

Setup mouse:
1. Install logiops: https://github.com/PixlOne/logiops
2. Run logid and copy name of mouse.
   For example:
   $ sudo logid
   [INFO] Device found: Wireless Mouse MX Master 3 on /dev/hidraw1:1
   Means name is "Wireless Mouse MX Master 3"
3. Put this name into logid.cfg
4. Copy logid.cfg to /etc/logid.cfg
5. sudo systemctl enable --now logid



