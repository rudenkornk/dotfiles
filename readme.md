# dotfiles

[![GitHub Actions Status](https://github.com/rudenkornk/dotfiles/actions/workflows/workflow.yml/badge.svg)](https://github.com/rudenkornk/dotfiles/actions)

Simple repo for setting up new system or user.

## Test
### Option 1: Use docker container
```bash
make in_docker TARGET=config
```

### Option 2: Use docker container interactively:
```bash
make dotfiles_container
docker attach dotfiles_container
make config
```

## Bootstrap
```bash
sudo apt-get install git make && \
  git clone https://github.com/rudenkornk/dotfiles ~/projects/dotfiles && \
  cd ~/projects/dotfiles && make config
# Reload shell
```
`WARNING:` do not run make as sudo, or it will install configs for root user.
Instead, either enter sudo password when requested, or ask system administrator to install necessary packages and then run `make config_user`.

