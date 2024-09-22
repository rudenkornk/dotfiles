#!/usr/bin/env bash

F=${1:-$HOME/projects/dotfiles/uv.lock}

N=15
SUM=0

for ((i = 1; i <= N; i++)); do
  nvim --startuptime time --headless "$F" -c q
  T=$(tail -n 2 time | head -1 | awk '{print $1}')
  SUM=$(echo "$SUM + $T" | bc)
  rm --force time
done
echo "Average: $(echo "$SUM / $N" | bc) ms"
