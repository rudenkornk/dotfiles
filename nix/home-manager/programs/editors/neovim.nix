{ pkgs, config, ... }:

# See also https://github.com/LazyVim/LazyVim/discussions/1972
{
  programs = {

    neovim = {
      enable = true;
      defaultEditor = true;
      withNodeJs = true;
      withPython3 = true;
      withRuby = true;

      plugins = [ pkgs.unstable.vimPlugins.lazy-nvim ]; # Only lazy-nvim itself is loaded as a Neovim plugin.

      extraWrapperArgs = [
        "--run"
        # bash
        ''
          ${pkgs.locallib.bash_secrets}

          # Workaround for https://github.com/iamcco/markdown-preview.nvim/issues/737
          export NVIM_MKDP_LOG_FILE="/tmp/mkdp-nvim-$USER.log"
        ''
        # User-wide lua 5.4 installation shadows normal `extraPackages` lua 5.1.
        # Thus, overriding it with extraWrapperArgs to ensure the correct lua is used.
        "--prefix"
        "PATH"
        ":"
        "${pkgs.lua5_1}/bin/"
      ];

      extraLuaPackages =
        luaPkgs: with luaPkgs; [
          jsregexp
          luacheck
          luafilesystem
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
          lua51Packages.luarocks
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

      "nvim/lua/config/nix_managed_plugins.lua".text = # Comment preventing fold.
        ''return "${import ./neovim/plugins.nix { inherit pkgs; }}"'';
    };

    dataFile =
      let
        treesitterGrammars = pkgs.symlinkJoin {
          name = "nvim-treesitter-grammars";
          paths = pkgs.unstable.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
        };
      in
      {
        "nvim/site/parser".source = "${treesitterGrammars}/parser/";
        "nvim/site/queries".source = "${treesitterGrammars}/queries/";

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
