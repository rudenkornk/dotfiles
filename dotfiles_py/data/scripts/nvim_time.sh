#!/usr/bin/env bash

F=${1:-$HOME/projects/dotfiles/uv.lock}

hyperfine "nvim $F -c q"
