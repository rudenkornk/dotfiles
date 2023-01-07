# dotfiles

[![GitHub Actions Status](https://github.com/rudenkornk/dotfiles/actions/workflows/workflow.yml/badge.svg)](https://github.com/rudenkornk/dotfiles/actions)

Ansible playbooks, which set up dotfiles on the new system.

## Bootstrap
```bash
sudo apt-get update && \
sudo apt-get install git make --yes --no-install-recommends && \
  git clone https://github.com/rudenkornk/dotfiles ~/projects/dotfiles && \
  cd ~/projects/dotfiles && make
```

In neovim after it installs all the stuff run:
```vim
:Copilot auth
```

## Update components versions
```bash
make update
```

## Show role dependency graph
```bash
make graph
```

## Test
```bash
make lint
make check UBUNTU_TAG=22.04
make check UBUNTU_TAG=22.10
```


## Manual tests
### fzf
```bash
podman exec -it -u $(id -u) dotfiles_22.04 fish
ctrl-t # opens fzf search directory panels with list of files and syntax highlighted file contnent
ctrl-y # opens fzf ripgrep search
ctrl-g # in git repo opens fzf git history
ctrl-o # in git repo opens fzf git status
ctrl-r # opens fzf shell history
ctrl-v # opens fzf variables list
ctrl-x # opens fzf processes list, which updates when pressing ctrl-x again
```

When splitting tmux window in two panes and opening any fzf search in any git repo in one of the panes, changing focus between panes should not insert any weird (like "O" and "I") characters in fzf search bar.

### tmux
When creating new window or pane in tmux, it should open directory of the last visited pane.
