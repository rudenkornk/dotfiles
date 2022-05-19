# dotfiles

[![GitHub Actions Status](https://github.com/rudenkornk/dotfiles/actions/workflows/workflow.yml/badge.svg)](https://github.com/rudenkornk/dotfiles/actions)

Simple repo for setting up new system or user.

## Test
### Option 1: Use docker container
```bash
DOCKER_TARGET=config make in_docker
```

### Option 2: Use docker container interactively:
```bash
make dotfiles_container
docker attach dotfiles_container
make config
```

## Set up
```bash
make config
# Reload shell
```

