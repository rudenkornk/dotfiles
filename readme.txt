# Dotfiles readme
Informal descripition, which should be rewritten as some setup script

Setup keyboard:
1. Copy rnk to /usr/share/X11/xkb/symbols
2. Insert contents of evdev.xml into /usr/share/X11/xkb/rules/evdev.xml into appropriate place
3. Copy rnk-russian-qwerty.vim to /usr/share/vim/vim*/keymap/
4. Use .vimrc file
5. sudo dpkg-reconfigure xkb-data


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



c++ dev:
sudo apt install clang clang-format clang-tidy

Install xsel package for tmux-yank
sudo apt install xsel

Install symlinks
ln -s dotfiles/vimrc .vimrc
ln -s dotfiles/tmux.conf .tmux.conf
ln -s dotfiles/gitconfig .gitconfig

VIM plugins:
mkdir -p ~/.vim/pack/plugins/start

cd ~
git clone https://github.com/sonph/onehalf --depth 1 --recursive
cp -r onehalf/vim ~/.vim/pack/plugins/start/onehalf

xfce4 terminal:
mkdir --parents ~/.local/share/xfce4/terminal/colorschemes
cp onehalf/xfce4-terminal/OneHalfDark.theme ~/.local/share/xfce4/terminal/colorschemes/
cp onehalf/xfce4-terminal/OneHalfLight.theme ~/.local/share/xfce4/terminal/colorschemes

cd ~/.vim/pack/plugins/start

vim-surround:
mkdir -p ~/.vim/pack/tpope/start
cd ~/.vim/pack/tpope/start
git clone https://github.com/tpope/vim-surround --depth 1 --recursive
vim -u NONE -c "helptags vim-surround/doc" -c q

git clone https://github.com/vim-airline/vim-airline --depth 1 --recursive
vim -u NONE -c "helptags vim-airline/doc" -c q

git clone https://github.com/vim-airline/vim-airline-themes --depth 1 --recursive
vim -u NONE -c "helptags vim-airline-themes/doc" -c q

git clone https://github.com/itchyny/vim-cursorword --depth 1 --recursive
vim -u NONE -c "helptags vim-cursorword/doc" -c q

# Only for vim < 8.2.2345
git clone https://github.com/tmux-plugins/vim-tmux-focus-events --depth 1 --recursive
vim -u NONE -c "helptags vim-tmux-focus-events/doc" -c q

git clone https://github.com/tmux-plugins/vim-tmux --depth 1 --recursive
vim -u NONE -c "helptags vim-tmux/doc" -c q

git clone https://github.com/roxma/vim-tmux-clipboard --depth 1 --recursive
vim -u NONE -c "helptags vim-tmux-clipboard/doc" -c q

YouCompleteMe:
mkdir -p ~/.vim/pack/ycm-core/start
cd ~/.vim/pack/ycm-core/start
git clone https://github.com/ycm-core/YouCompleteMe --depth 1 --recursive
vim -u NONE -c "helptags YouCompleteMe/doc" -c q
cd YouCompleteMe
python3 install.py --clangd-completer

bashrc:
stty erase '^?'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias tmux='tmux -2 -u'
export PS1="\[\e[1;32m\]${debian_chroot:+($debian_chroot)}\u@\h:\[\e[m\]\[\e[0;36m\]\w\\[\e[m\]$ "

imwheel --kill --buttons "4 5"
imwheel --kill --quit
source /usr/share/bash-completion/completions/git

