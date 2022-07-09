-- Alternative to Navigator.nvim + vim-tmux-clipboard is
-- aserowy/tmux.nvim: copy sync does not work
return {
  config = function()
    require("Navigator").setup()
  end,
}
