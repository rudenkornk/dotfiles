{ pkgs, ... }:

{
  enable = true;
  defaultEditor = true;
  withNodeJs = true;
  withPython3 = true;
  withRuby = true;

  extraLuaPackages =
    luaPkgs: with luaPkgs; [
      jsregexp
      luacheck
      luafilesystem
      luarocks
      luasec
    ];

  extraPython3Packages =
    pythonPkgs: with pythonPkgs; [
      black
      debugpy
      flake8
      isort
      libtmux
      mypy
      packaging
      pip
      psutil
      pydocstyle
      pygments
      pygobject3
      pylint
      pynvim
      ruff
      sympy
      virtualenv
      yamllint
    ];

  extraPackages =
    (with pkgs.perlPackages; [
      Appcpanminus
      ArchiveTar
      FileHomeDir
      Graph
      LogLog4perl
      NeovimExt
      UnicodeString
      YAMLTiny
    ])
    ++ (with pkgs.vscode-extensions; [
      dbaeumer.vscode-eslint
      gleam.gleam
      mathiasfrohlich.kotlin
      redhat.ansible
      xdebug.php-debug
    ])
    ++ (with pkgs; [
      actionlint
      angular-language-server
      astro-language-server
      bash-language-server
      beautysh
      clang-tools
      cpplint
      docker-compose-language-service
      dockerfile-language-server
      eslint
      ghalint
      gitlab-ci-ls
      gitleaks
      gitlint
      gleam
      gopls
      helm-ls
      imagemagick
      jq
      kotlin-language-server
      kube-linter
      lldb
      lua-language-server
      markdownlint-cli2
      marksman
      mermaid-cli
      neocmakelsp
      netcoredbg
      nil
      nixfmt
      nushell
      php
      phpactor
      pyright
      rubocop
      ruby-lsp
      shfmt
      statix
      stylua
      svelte-language-server
      tailwindcss-language-server
      taplo
      terraform-ls
      texlab
      tslib
      ty
      typescript-language-server
      vscode-js-debug
      vscode-json-languageserver
      vtsls
      vue-language-server
      yaml-language-server
      yamlfmt
      yamllint
      yq
    ]);
}
