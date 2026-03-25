{ pkgs, ... }:

let
  python = pkgs.python313;
  pythonPkgs = python.pkgs;
in
pkgs.mkShell {
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
    markdownlint-cli2
    mypy
    nixfmt
    prettier
    pythonPkgs.mdformat
    pythonPkgs.mdformat-gfm
    ruff
    shellcheck
    shfmt
    statix
    stylua
    typos
    yamllint

  ];

  shellHook = ''
    export PYTHONPATH="$PWD/src:$PWD:$PYTHONPATH"
    mkdir --parents __build
    echo -e '#!/usr/bin/env bash\n\npython3 -m dotfiles_py "$@"' > __build/dotfiles
    chmod +x __build/dotfiles
    export PATH="$PWD/__build:$PATH"

    echo "Welcome to the project devshell!"
  '';
}
