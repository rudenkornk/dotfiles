# dotfiles

A NixOS configuration.

## Bootstrap

<!--
mdformat-shfmt does not pick up .editorconfig settings for some reason.
Ideally, it should format .sh blocks exactly as all other .sh scripts in the project.
A bit worse solution is to disable mdformat-shfmt for this block only,
to avoid its hard-tabs indents.
BUT. mdformat does not have ignore comments!
Thus, we have to disable markdownlint for this block instead.
-->

<!-- markdownlint-disable MD010 -->

```bash
nix-shell -p git
git clone https://github.com/rudenkornk/dotfiles ~/projects/dotfiles &&
	cd ~/projects/dotfiles &&
	nixos-rebuild switch --flake .#default
```

<!-- markdownlint-enable MD010 -->

## Showcase

<img width="1916" alt="neovim_example" src="https://github.com/rudenkornk/dotfiles/assets/28059451/5af2a3fb-a84f-40f3-b6f0-70f6a36eadef">
<img width="1918" alt="tmux_fish_fzf_example" src="https://github.com/rudenkornk/dotfiles/assets/28059451/64b8f3cf-98ee-41d3-b081-40fe380d16a3">

## Features

1. **NixOS!**
1. **Stable and reproducible**.
1. **Easily updatable**.
1. **Secrets inside the repo**.
   All the credentials, ssh keys, VPN configs can be stored directly in the repo using
   [`sops`](https://github.com/getsops/sops) and
   [`age`](https://github.com/FiloSottile/age).
   Secret decryption is optional: config works even if secrets are not decrypted.
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

## Test

```bash
nix develop
dotfiles format --check
dotfiles lint
```
