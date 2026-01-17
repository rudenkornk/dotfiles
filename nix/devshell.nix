{ pkgs, ... }:

pkgs.mkShell {
  packages = with pkgs; [
    # Bootstrap python & python packages.
    python313
    uv

    # Tools for dumping gnome settings.
    dconf
    dconf2nix

    # Format & lint tools.
    fish
    git
    gitleaks
    markdownlint-cli2
    nixfmt
    prettier
    ruff
    shellcheck
    shfmt
    statix
    stylua
    typos
  ];

  shellHook = ''
    uv sync
    source .venv/bin/activate
    echo "Welcome to the project devshell!"
  '';
}
