#!/usr/bin/env bash

version=${1:-2}

mkdir --parents ~/.local/share/nvim_versions/nvim_"$version"/cache
mkdir --parents ~/.local/share/nvim_versions/nvim_"$version"/config
mkdir --parents ~/.local/share/nvim_versions/nvim_"$version"/share

ln --symbolic --force --no-target-directory ~/.local/share/nvim_versions/nvim_"$version"/cache ~/.cache/nvim
ln --symbolic --force --no-target-directory ~/.local/share/nvim_versions/nvim_"$version"/config ~/.config/nvim
ln --symbolic --force --no-target-directory ~/.local/share/nvim_versions/nvim_"$version"/share ~/.local/share/nvim
