return {
  after = "nvim-cmp",
  requires = "nvim-lua/plenary.nvim",
  config = function()
    require("cmp_git").setup()
  end,
}
