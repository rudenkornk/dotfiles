-- Alternative to Navigator.nvim + vim-tmux-clipboard is
-- aserowy/tmux.nvim: copy sync does not work
return {
  cmd = {
    "NavigatorLeft",
    "NavigatorDown",
    "NavigatorUp",
    "NavigatorRight",
    "NavigatorPrevious",
  },
  config = function()
    require("Navigator").setup()
  end,
}
