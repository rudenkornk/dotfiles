local M = {}

-- Please do not reserve <A-b> and <A-f>
-- These keys are used by the floating terminal

M.keys = {
  {
    "<A-i>",
    function()
      require("dap").step_into()
    end,
    desc = "Step Into",
    mode = { "n", "t" },
  },
  {
    "<A-j>",
    function()
      require("dap").step_over()
    end,
    desc = "Step Over",
    mode = { "n", "t" },
  },
  {
    "<A-k>",
    function()
      require("dap").step_back()
    end,
    desc = "Step Back",
    mode = { "n", "t" },
  },
  {
    "<A-o>",
    function()
      require("dap").step_out()
    end,
    desc = "Step Out",
    mode = { "n", "t" },
  },
  {
    "<A-c>",
    function()
      require("dap").continue()
    end,
    desc = "Continue",
    mode = { "n", "t" },
  },
  {
    "<A-C>",
    function()
      require("dap").reverse_continue()
    end,
    desc = "Reverse Continue",
    mode = { "n", "t" },
  },
  {
    "<A-v>",
    function()
      require("dap").run_to_cursor()
    end,
    desc = "Run to Cursor",
    mode = { "n" },
  },
  {
    "<A-e>",
    function()
      require("dap").pause()
    end,
    desc = "Pause",
    mode = { "n", "t" },
  },
  {
    "<A-g>",
    function()
      require("dap").restart()
    end,
    desc = "Restart",
    mode = { "n", "t" },
  },
  {
    "<A-r>",
    function()
      require("dap").toggle_breakpoint()
    end,
    desc = "Toggle Breakpoint",
    mode = { "n" },
  },
  {
    "<A-R>",
    function()
      require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
    end,
    desc = "Breakpoint with condition",
    mode = { "n" },
  },
  {
    "<A-d>",
    function()
      require("dap").down()
    end,
    desc = "Down",
    mode = { "n", "t" },
  },
  {
    "<A-u>",
    function()
      require("dap").up()
    end,
    desc = "Up",
    mode = { "n", "t" },
  },
}

return M
