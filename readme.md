# dotfiles

[![GitHub Actions Status](https://github.com/rudenkornk/dotfiles/actions/workflows/workflow.yml/badge.svg)](https://github.com/rudenkornk/dotfiles/actions)

Simple repo for setting up new system or user.

## Test
```bash
make in_docker TARGET=config
docker attach dotfiles_container
fish
```

Reload tmux environment with `C-s I` and run in neovim commands:
```vim
:PackerSync
:MasonInstallAll
```

## Bootstrap
```bash
sudo apt-get update && \
sudo apt-get install git make && \
  git clone https://github.com/rudenkornk/dotfiles ~/projects/dotfiles && \
  cd ~/projects/dotfiles && make config
```
Reload tmux environment with `C-s I` and run in neovim commands:
```vim
:PackerSync
:MasonInstallAll
```
`WARNING:` do not run make as sudo, or it will install configs for root user.
Instead, either enter sudo password when requested, or ask system administrator to install necessary packages and then run `make config_user`.

