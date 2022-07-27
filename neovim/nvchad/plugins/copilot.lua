return {
  after = "nvim-cmp",
  config = function()
    require("copilot").setup()
  end,
}
