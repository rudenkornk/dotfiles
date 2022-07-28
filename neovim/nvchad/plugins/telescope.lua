return {
  defaults = {
    mappings = {
      i = {
        ["<C-f>"] = "results_scrolling_down",
        ["<C-b>"] = "results_scrolling_up",
        ["<C-a>"] = { "<ESC>^Wi", type = "command" },
      },
    },
    scroll_strategy = "limit",
  },
}
