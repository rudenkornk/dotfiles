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
export PROJECTS_PATH=~/projects; \
  git clone https://github.com/rudenkornk/dotfiles $PROJECTS_PATH/dotfiles && \
  cd $PROJECTS_PATH/dotfiles && sudo apt-get install make && make config
# Reload shell
```

