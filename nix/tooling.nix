{ pkgs, ... }:

let
  python = pkgs.python313;
  pythonPkgs = python.pkgs;

  # Python libraries of the `dotfiles` CLI itself, plus the markdown formatter:
  # `mdformat` and its plugins must live in the same python env to see each other.
  pythonLibs =
    ps: with ps; [
      click
      rich
      ruamel-yaml
      typer

      mdformat
      mdformat-beautysh
      mdformat-gfm
    ];

  # Tools the `dotfiles` CLI shells out to, shared between the dev shell and the CLI package.
  tools = with pkgs; [
    # Tools for dumping gnome settings.
    dconf
    dconf2nix

    # Format & lint tools.
    fish
    git
    gitleaks
    kdlfmt
    markdownlint-cli2
    mypy
    nixfmt
    prettier
    ruff
    shellcheck
    shfmt
    statix
    stylua
    typos
    yamllint
  ];
in
{
  devShells = {
    default = pkgs.mkShell {
      # Bootstrap python & python library dependencies.
      packages = [ python ] ++ pythonLibs pythonPkgs ++ tools;

      shellHook =
        # bash
        ''
          export PYTHONPATH="$PWD/src:$PWD:$PYTHONPATH"
          mkdir --parents __build
          echo -e '#!/usr/bin/env bash\n\npython3 -m dotfiles_py "$@"' > __build/dotfiles
          chmod +x __build/dotfiles
          export PATH="$PWD/__build:$PATH"

          # Hook setup is an idempotent symlink refresh, so it is safe to run on every shell entry.
          # Worktrees are skipped (`.git` is a file there); they share the main checkout's hooks anyway.
          if [ -d .git ]; then
            dotfiles --log-level warning hooks
          fi

          echo "Welcome to the project devshell!"
        '';
    };

    install = pkgs.mkShell {
      packages = with pkgs; [
        disko
        e2fsprogs # chattr, lsattr, etc.
        mokutil
        nixos-install
        sbctl
        vim
      ];

      shellHook =
        # bash
        ''
          echo "You are in the project NixOS install shell."
          echo "It is supposed to run from inside NixOS live OS via:"
          echo ""
          echo "sudo nix --extra-experimental-features \"nix-command flakes\" develop .#install"
          echo ""
          echo 'After that `disko`, `sbctl` and `nixos-install` can be used to install or recover the system.'
        '';
    };
  };
}
