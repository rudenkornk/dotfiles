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
    "${config.xdg.configHome}/luacheck/.luacheckrc".source =
      ./linters/configs/.config/luacheck/.luacheckrc;
    "${config.xdg.configHome}/yamlfmt/.yamlfmt".source = ./linters/configs/.config/yamlfmt/.yamlfmt;
    "${config.xdg.configHome}/yamllint/config".source = ./linters/configs/.config/yamllint/config;
    "${config.xdg.configHome}/black".source = ./linters/configs/.config/black;
    "${config.xdg.configHome}/pycodestyle".source = ./linters/configs/.config/pycodestyle;
    "${config.xdg.configHome}/pylintrc".source = ./linters/configs/.config/pylintrc;
    ".groovylintrc.json".source = ./linters/configs/.groovylintrc.json;
    ".isort.cfg".source = ./linters/configs/.isort.cfg;
    ".markdownlint.yaml".source = ./linters/configs/.markdownlint.yaml;
    ".pydocstyle".source = ./linters/configs/.pydocstyle;
  };

  imports = [
    ./linters/mypy.nix
    ./linters/ruff.nix
  ];
}
