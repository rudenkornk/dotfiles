{ pkgs, ... }:

let
  python = pkgs.python313;
  pythonPkgs = python.pkgs;
in
{
  default = pkgs.mkShell {
    packages = with pkgs; [
      # Bootstrap python & python library dependencies.
      python
      pythonPkgs.click
      pythonPkgs.rich
      pythonPkgs.ruamel-yaml
      pythonPkgs.typer

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
      pythonPkgs.mdformat
      pythonPkgs.mdformat-beautysh
      pythonPkgs.mdformat-gfm
      ruff
      shellcheck
      shfmt
      statix
      stylua
      typos
      yamllint

    ];

    shellHook =
      # bash
      ''
        export PYTHONPATH="$PWD/src:$PWD:$PYTHONPATH"
        mkdir --parents __build
        echo -e '#!/usr/bin/env bash\n\npython3 -m dotfiles_py "$@"' > __build/dotfiles
        chmod +x __build/dotfiles
        export PATH="$PWD/__build:$PATH"

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
}
