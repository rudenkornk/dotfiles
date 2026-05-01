{ pkgs, ... }:

let
  plugins = with pkgs.unstable.vimPlugins; [

    async-nvim
    aerial-nvim
    baleia-nvim
    better-escape-nvim
    blink-cmp
    blink-compat
    blink-copilot
    bufferline-nvim
    clangd_extensions-nvim
    cmake-tools-nvim
    cmp-emoji
    cmp-tmux
    conform-nvim
    conjure
    copilot-lua
    crates-nvim
    dial-nvim
    dracula-nvim
    duck-nvim
    everforest
    flash-nvim
    flit-nvim
    friendly-snippets
    gh-nvim
    gitsigns-nvim
    grug-far-nvim
    gruvbox-nvim
    haskell-snippets-nvim
    haskell-tools-nvim
    helm-ls-nvim
    inc-rename-nvim
    iron-nvim
    jupytext-nvim
    lazy-nvim
    lazydev-nvim
    lean-nvim
    litee-nvim
    lualine-nvim
    luasnip
    markdown-preview-nvim
    mini-ai
    mini-comment
    mini-diff
    mini-files
    mini-hipatterns
    mini-icons
    mini-indentscope
    mini-move
    mini-pairs
    mini-surround
    minuet-ai-nvim
    neo-tree-nvim
    neogen
    neotest
    neotest-bash
    neotest-dart
    neotest-go
    neotest-golang
    neotest-gtest
    neotest-haskell
    neotest-pest
    neotest-phpunit
    neotest-python
    neotest-rspec
    neotest-rust
    neotest-zig
    noice-nvim # typos: ignore
    nord-nvim
    NotebookNavigator-nvim
    nui-nvim
    nvim-ansible
    nvim-dap
    nvim-dap-go
    nvim-dap-lldb
    nvim-dap-python
    nvim-dap-ruby
    nvim-dap-ui
    nvim-dap-virtual-text
    nvim-jdtls
    nvim-lint
    nvim-lspconfig
    nvim-metals
    nvim-navic
    nvim-nio
    nvim-paredit
    nvim-scrollbar
    nvim-treesitter
    nvim-treesitter-context
    nvim-treesitter-textobjects
    nvim-ts-autotag
    nvim-ts-context-commentstring
    one-small-step-for-vimkind
    onedark-nvim
    outline-nvim
    persistence-nvim
    plenary-nvim
    refactoring-nvim
    render-markdown-nvim
    rose-pine
    rustaceanvim
    SchemaStore-nvim
    sidekick-nvim
    snacks-nvim
    tmux-nvim
    todo-comments-nvim
    tokyonight-nvim
    trouble-nvim
    ts-comments-nvim
    typst-preview-nvim
    venv-selector-nvim
    vim-dadbod
    vim-dadbod-completion
    vim-dadbod-ui
    vim-illuminate
    vim-repeat
    vim-startuptime
    vimtex
    vscode-nvim
    which-key-nvim
    yanky-nvim

    # When a plugin's name in nixpkgs doesn't match what Lazy expects, manually specify the name.
    {
      name = "catppuccin";
      path = catppuccin-nvim;
    }
    {
      name = "LuaSnip";
      path = luasnip;
    }
    {
      name = "FluoroMachine.nvim";
      path = fluoromachine-nvim;
    }

    # TODO: remove this W/A once LazyVim supports all the quirks.
    # Special treatment for leap, which migrated to new repo and also rewritten some code.
    # LazyVim seemingly adapted, but for some reason it does not work.
    pkgs.vimPlugins.leap-nvim # Use old leap.
    pkgs.vimPlugins.LazyVim # Use old LazyVim.

  ];

  # Maps a plugin derivation to a { name, path } pair.
  # linkFarm expects this format to create a directory of symlinks
  # where each plugin is accessible by its name.
  mkEntryFromDrv =
    drv:
    if pkgs.lib.isDerivation drv then
      {
        name = "${pkgs.lib.getName drv}";
        path = drv;
      }
    else
      drv;

  # Creates a directory with symlinks to all plugins, keyed by name.
  # This is what Lazy uses as its local plugin source via dev.path.
  lazyPath = pkgs.linkFarm "lazy-plugins" (builtins.map mkEntryFromDrv plugins);
in
lazyPath
