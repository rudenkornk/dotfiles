{ pkgs, config, ... }:

# See also https://github.com/LazyVim/LazyVim/discussions/1972
{
  programs = {

    neovim = {
      enable = true;
      defaultEditor = true;
      withNodeJs = true;
      withPerl = true;
      withPython3 = true;
      withRuby = true;

      # We manage `init.lua` ourselves via the recursive `xdg.configFile."nvim"` below.
      # Without this, our `config/init.lua` clobbers the one home-manager generates,
      # which carries the `extraLuaPackages` `package.path`/`cpath` bootstrap and the provider host vars,
      # so `require("jsregexp")` and the Node provider break.
      # With this set, home-manager loads that bootstrap through a wrapper `--cmd` instead.
      sideloadInitLua = true;

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
          magick
        ];

      extraPython3Packages =
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
        ];

      # The perl provider is wired up by `withPerl` above, which builds its own perl env
      # with `Neovim::Ext`. No perl packages are needed here.
      extraPackages = with pkgs; [
        ghostscript
        imagemagick
        lua51Packages.luarocks
        tree-sitter
        virtualenv
        websocat # For typst.
      ];
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

      # `snacks.picker` loads sqlite3 through luajit ffi. There is no global library path on NixOS,
      # so we hand it the absolute path to `libsqlite3.so`. Otherwise it falls back to file storage.
      "nvim/lua/config/nix_sqlite.lua".text = # Comment preventing fold.
        ''return "${pkgs.sqlite.out}/lib/libsqlite3.so"'';
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
        # Queries come from the plugin, not the grammar derivations. The latter omit the
        # inheritance-only base modules (`ecma`, `jsx`, `html_tags`), so every language whose
        # query does `; inherits: ecma` (javascript, typescript, tsx, vue, svelte, ...) fails to load.
        # The plugin ships the complete curated set; it is identical to the grammar queries otherwise.
        "nvim/site/queries".source = "${pkgs.unstable.vimPlugins.nvim-treesitter}/runtime/queries/";
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
          "${pkgs.vscode-js-debug}/lib/node_modules/js-debug/dist/src/dapDebugServer.js";
        "nvim/mason/packages/vue-language-server/node_modules/@vue/language-server".source =
          "${pkgs.vue-language-server}/lib/language-tools/packages/language-server";
      };

  };

  home = {
    packages = with pkgs; [
      inotify-tools # Faster LSP file watching than the libuv fallback.
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
      WORDLIST = "${pkgs.scowl}/share/dict/words.txt"; # English word list for generic text completion.
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
