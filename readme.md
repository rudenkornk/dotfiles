# dotfiles

Ansible playbooks, which idempotently configure new system with a single bootstrap command.

## Bootstrap

```bash
sudo apt-get update && \
sudo apt-get install git make --yes --no-install-recommends && \
git clone https://github.com/rudenkornk/dotfiles ~/projects/dotfiles && \
cd ~/projects/dotfiles && make
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
   Packages, managed by `apt` cannot be pinned, so I rely on stability of `Canonical` packages update front.
1. **Easily updatable**.
   Versions are stored in manifests and can be easily updated with a single command.
   `neovim`'s `lazy-lock.json` however is managed separately by [lazy](https://github.com/folke/lazy.nvim).
1. **Supports & tested under `Ubuntu 22.04`, `Ubuntu 23.04`, `Ubuntu 23.10`, `Ubuntu 24.04`, and also includes WSL support**.
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
make check_host
podman exec --interactive --tty --workdir $(pwd) --user $(id --user) dotfiles_22.04 fish
```

## Fork

The first things you would want to customize if forking this repo are:

1. Personal information in `roles/profile/vars/main.yaml`.
1. Credentials, ssh keys and vpn configs in `roles/secrets/files`.

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
make check IMAGE=ubuntu:22.04
```
