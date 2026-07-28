# Neovim, wrapped with its lua config, plugins and providers baked in.
# Treesitter grammars, spell files and the mason workarounds stay as
# `xdg.dataFile` links: they emulate mutable `stdpath('data')` state, so a bare
# `nix run .#nvim` elsewhere works with degraded mason LSPs only.
# See also https://github.com/LazyVim/LazyVim/discussions/1972
{ config, ... }:
let
  flakeCfg = config;
in
{
  flake = {
    wrappers.fish =
      { pkgs, ... }:
      let
        fishlib = import ../shell/_fish/lib.nix;
      in
      {
        shellAliases = {
          v = "nvim";
          vd = "nvim -d";
        };
        plugins = [
          (fishlib.mkSnippet pkgs "60-neovim" (builtins.readFile ./_neovim/fish/conf.d/neovim.fish))
        ];
      };

    wrappers.nvim =
      {
        wlib,
        pkgs,
        lib,
        ...
      }:
      {
        imports = [
          wlib.wrapperModules.neovim
          ../secrets/_fragments/secret-env.nix
        ];

        package = pkgs.neovim-unwrapped;

        settings = {
          config_directory = pkgs.runCommand "nvim-config" { } ''
            cp -r ${./_neovim/config} $out
            chmod -R u+w $out
            cat > $out/lua/config/nix_managed_plugins.lua << 'EOF'
            return "${import ./_neovim/plugins.nix { inherit pkgs; }}"
            EOF
          '';
          nvim_lua_env =
            lp: with lp; [
              jsregexp
              luacheck
              luafilesystem
              luasec
              magick
            ];
        };

        # Only lazy-nvim itself is loaded as a Neovim plugin.
        specs.lazy-nvim = pkgs.unstable.vimPlugins.lazy-nvim;

        hosts = {
          python3 = {
            package = lib.mkForce (
              pkgs.python313.withPackages (
                pythonPkgs: with pythonPkgs; [
                  jupyter-client
                  libtmux
                  packaging
                  pip
                  psutil
                  pygments
                  pygobject3
                  pynvim
                  sympy
                ]
              )
            );
            nvim-host.enable = true;
          };
          node = {
            package = lib.mkForce pkgs.neovim-node-client;
            nvim-host.enable = true;
          };
          # NOTE: the ruby provider (formerly `withRuby`) is dropped; nothing in
          # this configuration uses ruby remote plugins.
        };

        runShell = [
          {
            name = "mkdp-log";
            after = [ "secret-env" ];
            # Workaround for https://github.com/iamcco/markdown-preview.nvim/issues/737
            data = ''export NVIM_MKDP_LOG_FILE="/tmp/mkdp-nvim-$USER.log"'';
          }
        ];

        # User-wide lua 5.4 installation shadows the wrapper's lua 5.1.
        # Prefixing PATH ensures the correct lua is used.
        prefixVar = [
          [
            "PATH"
            ":"
            "${pkgs.lua5_1}/bin"
          ]
        ];

        runtimePkgs =
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

    modules.homeManager.base = { pkgs, ... }: {
      home = {
        packages = with pkgs; [
          flakeCfg.flake.packages.${pkgs.stdenv.hostPlatform.system}.nvim
          sqlite
          vim
          wl-clipboard
          xsel
        ];

        shellAliases = {
          v = "nvim";
          vd = "nvim -d";
        };

        sessionVariables = {
          EDITOR = "nvim";
        };
      };

      xdg = {
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
            "nvim/site/spell".source = "${pkgs.custom.vim-spell}/spell/";

            # Workaround for missing mason packages in neovim.
            # https://github.com/LazyVim/LazyVim/discussions/6892
            "nvim/mason/packages/angular-language-server/node_modules/@angular/language-server".source =
              "${pkgs.angular-language-server}/lib";
            "nvim/mason/packages/astro-language-server/node_modules/@astrojs/ts-plugin".source =
              "${pkgs.astro-language-server}/lib/node_modules/astro-language-server/packages/language-tools/ts-plugin/";
            "nvim/mason/packages/svelte-language-server/node_modules/typescript-svelte-plugin".source =
              "${pkgs.svelte-language-server}/lib/node_modules/svelte-language-server/packages/typescript-plugin/";
            "nvim/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js".source =
              "${pkgs.vscode-js-debug}/lib/node_modules/js-debug/src/dapDebugServer.ts";
            "nvim/mason/packages/vue-language-server/node_modules/@vue/language-server".source =
              "${pkgs.vue-language-server}/lib/language-tools/packages/language-server";
          };
      };

      programs = {
        bash = {
          initExtra = builtins.readFile ./_neovim/bash/init_extra.sh;
        };
      };
    };
  };
}
