{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;

    extraWrapperArgs = [
      "--run"
      ''
        source <(${pkgs.sops}/bin/sops --decrypt ${../secrets/proxy.sh.sops} 2>/dev/null)
        source <(${pkgs.sops}/bin/sops --decrypt ${../secrets/keys.sh.sops} 2>/dev/null)
      ''
    ];

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
        vadimcn.vscode-lldb
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
  };

  home = {
    packages = with pkgs; [
      angular-language-server
      astro-language-server
      svelte-language-server
      vscode-js-debug
      vue-language-server

      xsel
      python3Packages.debugpy
    ];

    file = {
      ".config/nvim" = {
        source = ./neovim/config;
        recursive = true;
      };

      # Workaround for missing mason packages in neovim.
      # https://github.com/LazyVim/LazyVim/discussions/6892
      ".local/share/nvim/mason/packages/angular-language-server/node_modules/@angular/language-server".source =
        "${pkgs.angular-language-server}/lib";
      ".local/share/nvim/mason/packages/astro-language-server/node_modules/@astrojs/ts-plugin".source =
        "${pkgs.astro-language-server}/lib/astro-language-server/packages/ts-plugin/";
      ".local/share/nvim/mason/packages/svelte-language-server/node_modules/typescript-svelte-plugin".source =
        "${pkgs.svelte-language-server}/lib/node_modules/svelte-language-server/packages/typescript-plugin/";
      ".local/share/nvim/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js".source =
        "${pkgs.vscode-js-debug}/lib/node_modules/js-debug/src/dapDebugServer.ts";
      ".local/share/nvim/mason/packages/vue-language-server/node_modules/@vue/language-server".source =
        "${pkgs.vue-language-server}/lib/language-tools/packages/language-server";
    };
  };
}
