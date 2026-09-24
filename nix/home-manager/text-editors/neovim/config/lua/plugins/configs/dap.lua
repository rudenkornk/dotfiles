local M = {}

M.opts = function()
  -- CodeLLDB listens on IPv4, but localhost can resolve to IPv6.
  require("dap").adapters.codelldb.host = "127.0.0.1"

  vim.api.nvim_create_autocmd("InsertEnter", {
    group = vim.api.nvim_create_augroup("dap_repl_keymaps", { clear = true }),
    callback = function(event)
      if vim.bo[event.buf].filetype ~= "dap-repl" then
        return
      end

      -- Blink installs buffer-local mappings on InsertEnter, so apply the console bindings afterward.
      vim.schedule(function()
        vim.keymap.set("i", "<C-n>", function()
          local cmp = require("blink.cmp")
          if cmp.is_menu_visible() then
            cmp.select_next()
          else
            require("dap.repl").on_down()
          end
        end, { buffer = event.buf, desc = "Next Completion or Command" })
        vim.keymap.set("i", "<C-p>", function()
          local cmp = require("blink.cmp")
          if cmp.is_menu_visible() then
            cmp.select_prev()
          else
            require("dap.repl").on_up()
          end
        end, { buffer = event.buf, desc = "Previous Completion or Command" })
        vim.keymap.set("i", "<A-b>", "<C-Left>", { buffer = event.buf, desc = "Previous Word" })
        vim.keymap.set("i", "<A-f>", "<C-Right>", { buffer = event.buf, desc = "Next Word" })
        -- Native <C-w> is ignored in our Neovim 0.12 prompt buffers.
        -- Do not wait for the tmux <C-w> navigation chords.
        vim.keymap.set("i", "<C-w>", function()
          local row, col = unpack(vim.api.nvim_win_get_cursor(0))
          local prompt_length = #vim.fn.prompt_getprompt(event.buf)
          local input = vim.api.nvim_get_current_line():sub(prompt_length + 1, col)
          local start = prompt_length + #(input:match("^(.*%s)%S+%s*$") or "")
          vim.api.nvim_buf_set_text(event.buf, row - 1, start, row - 1, col, { "" })
          vim.api.nvim_win_set_cursor(0, { row, start })
        end, { buffer = event.buf, nowait = true, desc = "Delete Previous Word" })
      end)
    end,
  })
end

-- Please do not reserve `<A-b>` and `<A-f>`.
-- These keys are used by the floating terminal.

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
    "<A-m>",
    function()
      require("dap").step_over()
    end,
    desc = "Step Over",
    mode = { "n", "t" },
  },
  {
    "<A-q>",
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
