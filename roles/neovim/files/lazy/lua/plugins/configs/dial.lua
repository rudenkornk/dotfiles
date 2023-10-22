local M = {}

M.config = function()
  local augend = require("dial.augend")
  require("dial.config").augends:register_group({
    default = {
      augend.constant.alias.alpha,
      augend.constant.alias.Alpha,
      augend.constant.alias.bool,
      augend.constant.new({ elements = { "&&", "||" }, word = false }),
      augend.constant.new({ elements = { "and", "or" } }),
      augend.constant.new({ elements = { "AND", "OR" } }),
      augend.constant.new({ elements = { "ON", "OFF" } }),
      augend.constant.new({ elements = { "True", "False" } }),
      augend.constant.new({ elements = { "TRUE", "FALSE" } }),
      augend.integer.alias.binary,
      augend.integer.alias.decimal_int,
      augend.integer.alias.hex,
      augend.integer.alias.octal,
      augend.semver.alias.semver,
    },
  })
end

M.keys = {
  {
    "<C-a>",
    function()
      return require("dial.map").inc_normal()
    end,
    mode = { "n" },
    expr = true,
  },
  {
    "<C-x>",
    function()
      return require("dial.map").dec_normal()
    end,
    mode = { "n" },
    expr = true,
  },
  {
    "<C-a>",
    function()
      return require("dial.map").inc_visual()
    end,
    mode = { "v" },
    expr = true,
  },
  {
    "<C-x>",
    function()
      return require("dial.map").dec_visual()
    end,
    mode = { "v" },
    expr = true,
  },
  {
    "g<C-a>",
    function()
      return require("dial.map").inc_visual()
    end,
    mode = { "v" },
    expr = true,
  },
  {
    "g<C-x>",
    function()
      return require("dial.map").dec_visual()
    end,
    mode = { "v" },
    expr = true,
  },
}

return M
