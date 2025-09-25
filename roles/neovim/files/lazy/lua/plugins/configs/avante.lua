M = {}

-- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
-- ⚠️ must add this setting! ! !
M.build = "make"

M.opts = {
  provider = "copilot",
  input = {
    provider = "snacks",
    provider_opts = {
      -- Additional snacks.input options
      title = "Avante Input",
      icon = "󰇀",
    },
  },
  selector = {
    provider = "snacks",
    provider_opts = {},
  },
  mappings = {
    sidebar = {
      close_from_input = {
        normal = { "q", "<Esc>" },
        insert = "<C-d>",
      },
    },
    submit = {
      insert = "<C-g>",
    },
  },
}

return M
