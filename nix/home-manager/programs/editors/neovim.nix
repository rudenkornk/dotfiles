{ pkgs, config, ... }:

{
  programs = {

    neovim = {
      enable = true;
      defaultEditor = true;
      withNodeJs = true;
      withPython3 = true;
      withRuby = true;

      extraWrapperArgs = [
        "--run"
        # bash
        ''
          ${pkgs.locallib.bash_secrets}

          # Workaround for https://github.com/iamcco/markdown-preview.nvim/issues/737
          export NVIM_MKDP_LOG_FILE="/tmp/mkdp-nvim-$USER.log"
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

        # Other tools.
        ++ (with pkgs; [
          ghostscript
          imagemagick
          tree-sitter
          virtualenv
          websocat # For typst.
        ]);
    };

  };

  xdg = {
    configFile = {
      "nvim" = {
        source = ./neovim/config;
        recursive = true;
      };
    };

    dataFile = {
      # Workaround for missing mason packages in neovim.
      # https://github.com/LazyVim/LazyVim/discussions/6892
      "nvim/mason/packages/angular-language-server/node_modules/@angular/language-server".source =
        "${pkgs.angular-language-server}/lib";
      "nvim/mason/packages/astro-language-server/node_modules/@astrojs/ts-plugin".source =
        "${pkgs.astro-language-server}/lib/astro-language-server/packages/ts-plugin/";
      "nvim/mason/packages/svelte-language-server/node_modules/typescript-svelte-plugin".source =
        "${pkgs.svelte-language-server}/lib/node_modules/svelte-language-server/packages/typescript-plugin/";
      "nvim/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js".source =
        "${pkgs.vscode-js-debug}/lib/node_modules/js-debug/src/dapDebugServer.ts";
      "nvim/mason/packages/vue-language-server/node_modules/@vue/language-server".source =
        "${pkgs.vue-language-server}/lib/language-tools/packages/language-server";
    };
  };

  home = {
    packages = with pkgs; [
      sqlite
      vim
      wl-clipboard
      xsel
    ];

    shellAliases = {
      v = "nvim";
      vd = "nvim -d";
    };
  };

  programs = {
    fish = {
      interactiveShellInit = builtins.readFile ./neovim/fish/conf.d/neovim.fish;
    };
    bash = {
      initExtra = builtins.readFile ./neovim/bash/init_extra.sh;
    };
  };
}
