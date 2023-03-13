# dotfiles

Ansible playbooks, which set up dotfiles on the new system.

## Bootstrap

```bash
sudo apt-get update && \
sudo apt-get install git make --yes --no-install-recommends && \
git clone https://github.com/rudenkornk/dotfiles ~/projects/dotfiles && \
cd ~/projects/dotfiles && make
```

In neovim after it installs packer, mason and treesitter packages run:

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
