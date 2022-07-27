return {
  after = "nvim-cmp",
  config = function()
    local cmp = require("cmp")
    cmp.setup.cmdline("/", {
      mapping = require("cmp").mapping.preset.cmdline(),
      sources = {
        { name = "buffer" },
      },
    })
    cmp.setup.cmdline(":", {
      mapping = require("cmp").mapping.preset.cmdline(),
      sources = {
        { name = "cmdline" },
        { name = "path" },
      },
    })
  end,
}
