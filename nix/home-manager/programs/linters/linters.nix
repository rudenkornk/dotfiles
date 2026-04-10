{ pkgs, config, ... }:

# Formatters & linters.
{
  home.packages = with pkgs; [

    (lib.hiPrio gotools)
    actionlint
    ansible-lint
    beautysh
    black
    clang-tools
    cmake-lint
    cpplint
    eslint
    fourmolu
    ghalint
    gitleaks
    gitlint
    gofumpt
    golangci-lint
    haskellPackages.cabal-fmt
    isort
    kdlfmt
    ktlint
    kube-linter
    markdown-toc
    markdownlint-cli2
    mypy
    nixfmt
    phpPackages.php-cs-fixer
    prettier
    pylint
    python3Packages.flake8
    python3Packages.pydocstyle
    rubocop
    rubyPackages.erb-formatter
    ruff
    shellcheck
    shfmt
    sqlfluff
    statix
    stylua
    ty
    typos
    typstyle
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
