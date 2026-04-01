require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" }, -- Add LazyVim and import its plugins.
    { import = "plugins" }, -- Import/override with your plugins.
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = true,
    version = false, -- Always use the latest git commit.
  },
  checker = {
    enabled = false, -- Do not check for plugin updates.
  },
  dev = {
    path = require("config.nix_managed_plugins"), -- Reuse files from pkgs.vimPlugins.*
    patterns = { "." },
    fallback = true, -- If a plugin isn't found in the linkFarm, Lazy will fall back to downloading it.
  },
  performance = {
    rtp = {
      -- Disable some rtp plugins.
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
