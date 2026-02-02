{ pkgs, config, ... }:

# Formatters & linters.
{
  home.packages = with pkgs; [
    actionlint
    ansible-lint
    beautysh
    black
    clang-tools
    cpplint
    eslint
    ghalint
    gitleaks
    gitlint
    golangci-lint
    isort
    kube-linter
    markdownlint-cli2
    mypy
    nixfmt
    prettier
    pylint
    python3Packages.flake8
    python3Packages.pydocstyle
    rubocop
    ruff
    shellcheck
    shfmt
    statix
    stylua
    ty
    typos
    vscode-extensions.dbaeumer.vscode-eslint
    yamlfmt
    yamllint
  ];
  home.file = pkgs.locallib.homefiles {
    inherit (config) xdg;
    path = ./configs;
  };

  programs.mypy = {
    enable = true;
    settings = {
      mypy = {
        strict = true;
      };
    };
  };
}
