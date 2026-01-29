{ pkgs, ... }:

# Formatters & linters.
{
  home.packages = with pkgs; [
    ansible-lint
    gitleaks
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
  ];

  imports = [
    ./linters/mypy.nix
    ./linters/ruff.nix
  ];
}
