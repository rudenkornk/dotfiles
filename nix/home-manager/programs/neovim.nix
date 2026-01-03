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
        if [[ "$USERKIND" == "default" ]]; then
          source <(${pkgs.sops}/bin/sops --decrypt ${../secrets/proxy.sh.sops} 2>/dev/null)
          source <(${pkgs.sops}/bin/sops --decrypt ${../secrets/keys.sh.sops} 2>/dev/null)
        elif [[ "$USERKIND" == "corp" ]]; then
          source <(${pkgs.sops}/bin/sops --decrypt ${../secrets/corp_keys.sh.sops} 2>/dev/null)
        fi
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
        libtmux
        packaging
        pip
        psutil
        pygments
        pygobject3
        pynvim
        sympy
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

      ++ (with pkgs; [
        # Formatters & linters.
        actionlint
        beautysh
        black
        python3Packages.flake8
        clang-tools
        cpplint
        eslint
        ghalint
        gitleaks
        gitlint
        kube-linter
        markdownlint-cli2
        mypy
        nixfmt
        pylint
        rubocop
        ruff
        shfmt
        statix
        stylua
        ty
        vscode-extensions.dbaeumer.vscode-eslint
        yamlfmt
        yamllint
        isort
        python3Packages.pydocstyle

        # LSP servers.
        angular-language-server
        astro-language-server
        bash-language-server
        copilot-language-server
        docker-compose-language-service
        dockerfile-language-server
        gitlab-ci-ls
        gopls
        helm-ls
        kotlin-language-server
        lua-language-server
        marksman
        neocmakelsp
        nil
        phpactor
        pyright
        ruby-lsp
        svelte-language-server
        tailwindcss-language-server
        taplo
        terraform-ls
        texlab
        typescript-language-server
        vscode-extensions.gleam.gleam
        vscode-extensions.mathiasfrohlich.kotlin
        vscode-extensions.redhat.ansible
        vscode-json-languageserver
        vscode-langservers-extracted
        vtsls
        vue-language-server
        yaml-language-server
        zls

        # Compilers, interpreters & language processors.
        dotnet-sdk
        gleam
        jq
        mermaid-cli
        nushell
        php
        yq

        # Debuggers.
        lldb
        netcoredbg
        python3Packages.debugpy
        vscode-extensions.vadimcn.vscode-lldb
        vscode-extensions.xdebug.php-debug
        vscode-js-debug

        # Other tools.
        imagemagick
        tree-sitter
        virtualenv
        ghostscript
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
