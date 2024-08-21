# dotfiles

Ansible playbooks, which idempotently configure new system with a single bootstrap command.

## Bootstrap

```bash
git clone https://github.com/rudenkornk/dotfiles ~/projects/dotfiles && \
cd ~/projects/dotfiles && \
./main.sh config
```

## Showcase

<!-- markdownlint-disable no-inline-html -->
<img width="1916" alt="neovim_example" src="https://github.com/rudenkornk/dotfiles/assets/28059451/5af2a3fb-a84f-40f3-b6f0-70f6a36eadef">
<img width="1918" alt="tmux_fish_fzf_example" src="https://github.com/rudenkornk/dotfiles/assets/28059451/64b8f3cf-98ee-41d3-b081-40fe380d16a3">
<img width="1192" alt="deps_graph_example" src="https://github.com/rudenkornk/dotfiles/assets/28059451/b0dfe406-d44f-44cc-b6f7-9f469ee017e5">
<!-- markdownlint-enable no-inline-html -->

## Features

1. **Ansible!**
   Config utilizes a fully-fledged configuration manager, specifically designed to put machines into a desired end state.
   Config is idempotent and is capable of configuring not only `localhost`, but also several remote machines at once.
1. **Stable and reproducible**.
   All the program versions that _can_ be pinned _are_ pinned.
   Amongst other tools, that includes `ansible` itself, `neovim` and all its plugins.
   Packages, managed by `apt` and `dnf` cannot be pinned,
   so we rely on stability of `Canonical` and `RedHat` packages update front.
1. **Easily updatable**.
   Versions are stored in manifests and can be easily updated with a single command.
   `neovim`'s `lazy-lock.json` however is managed separately by [lazy](https://github.com/folke/lazy.nvim).
1. **Supports & tested under `Ubuntu 22.04-24.04`, `Fedora 38-40`, and also includes WSL support**.
   On Windows it integrates with the system clipboard.
1. **Secrets inside the repo**.
   All the credentials, ssh keys, VPN configs can be stored directly in the repo with support of the [git secret](https://github.com/sobolevn/git-secret).
   `gpg key` is optional: config works fine if it is not provided and secrets are not decrypted.
1. **Bootstrap with a single command.**
   Aside from `OS` limitations, there are zero requirements.

## Tools

While being decently generic, this config focuses more on some tools rather than others:

1. **Neovim**.
   `Neovim` config is based on [LazyVim](https://github.com/LazyVim/LazyVim).
   It follows all its guidelines and documentation adding tons of useful plugins on top,
   while still being "blazingly fast", thanks to lazy-loading.
1. **tmux**.
   `tmux` integrates with `Neovim`, which allows to seamlessly use keys for moving around and resizing windows.
1. **fish**.
   Main shell in this config is `fish`, which integrates with interactive `fzf`, `ripgrep` and `bat`.
   There is some support for `bash` though.
1. **C++**.
   Config provides releases of `cmake`, `LLVM` and `GCC` toolchains as well as editor support.
1. Config also provides some support for **Python**, **LaTeX** and **Lua**.

## Try this config

Config is tested inside `podman` containers, which can also be used to try this config.
Note, that this will install some tools (like `python` and `podman`) on your system.
This will not install any specific configs though.

```bash
./main.sh config --target dotfiles_ubuntu_22.04
podman exec --interactive --tty --workdir $(pwd) --user $(id --user) dotfiles_ubuntu_22.04 fish
```

## Fork

The first things you would want to customize if forking this repo are:

1. Personal information in `roles/profile/vars/main.yaml`.
1. Credentials, ssh keys and vpn configs shown in `git secret list`.

## Update components versions

```bash
./main.sh update
```

## Show role dependency graph

```bash
./main.sh graph
```

## Test

```bash
./main.sh
./main.sh config --target dotfiles_ubuntu_22.04
```
