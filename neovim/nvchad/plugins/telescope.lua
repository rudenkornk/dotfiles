return {
  defaults = {
    mappings = {
      i = {
        ["<C-f>"] = "results_scrolling_up",
        ["<C-b>"] = "results_scrolling_down",
        ["<C-a>"] = { "<ESC>^Wi", type = "command" },
      },
    },
  },
}
