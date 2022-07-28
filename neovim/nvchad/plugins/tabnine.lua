return {
  after = "nvim-cmp",
  module = "cmp_tabnine",
  run = "./install.sh",
  config = function()
    local tabnine = require("cmp_tabnine.config")
    tabnine:setup({
      max_num_results = 4,
      show_prediction_strength = true,
    })
  end,
}
