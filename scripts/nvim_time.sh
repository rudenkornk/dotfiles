#!/usr/bin/env bash

F=${1:-$HOME/projects/dotfiles/roles/neovim/files/nvchad2/plugins/init.lua}

N=30
SUM=0

for ((i=1;i<=N;i++)); do
  nvim --startuptime time --headless "$F" -c q
  T=$(tail -n 1 time | awk '{print $1}')
  SUM=$(echo "$SUM + $T" | bc)
  rm --force time
done
echo "Average: $(echo "$SUM / $N" | bc) ms"

