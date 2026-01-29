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

  home.file = {
    "${config.xdg.configHome}/luacheck/.luacheckrc".source = ./configs/.config/luacheck/.luacheckrc;
    "${config.xdg.configHome}/yamlfmt/.yamlfmt".source = ./configs/.config/yamlfmt/.yamlfmt;
    "${config.xdg.configHome}/yamllint/config".source = ./configs/.config/yamllint/config;
    "${config.xdg.configHome}/black".source = ./configs/.config/black;
    "${config.xdg.configHome}/pycodestyle".source = ./configs/.config/pycodestyle;
    "${config.xdg.configHome}/pylintrc".source = ./configs/.config/pylintrc;
    ".groovylintrc.json".source = ./configs/.groovylintrc.json;
    ".isort.cfg".source = ./configs/.isort.cfg;
    ".markdownlint.yaml".source = ./configs/.markdownlint.yaml;
    ".pydocstyle".source = ./configs/.pydocstyle;
  };
}
