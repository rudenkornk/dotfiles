#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

TERMINAL_COLORSCHEMES_DIR=~/.local/share/xfce4/terminal/colorschemes
mkdir --parents $TERMINAL_COLORSCHEMES_DIR

wget https://raw.githubusercontent.com/sonph/onehalf/master/xfce4-terminal/OneHalfDark.theme
wget https://raw.githubusercontent.com/sonph/onehalf/master/xfce4-terminal/OneHalfLight.theme

mv OneHalfDark.theme $TERMINAL_COLORSCHEMES_DIR
mv OneHalfLight.theme $TERMINAL_COLORSCHEMES_DIR

