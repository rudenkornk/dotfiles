-- see https://www.reddit.com/r/neovim/comments/ab01n8/improve_neovim_startup_by_60ms_for_free_on_macos/
-- and https://www.reddit.com/r/neovim/comments/wb2obw/how_to_setup_gclipboard_using_lua/
local clipboards = {
  ["win32yank"] = {
    name = "win32yank",
    copy = {
      ["+"] = { "win32yank.exe", "-i", "--crlf" },
      ["*"] = { "win32yank.exe", "-i", "--crlf" },
    },
    paste = {
      ["+"] = { "win32yank.exe", "-o", "--lf" },
      ["*"] = { "win32yank.exe", "-o", "--lf" },
    },
    cache_enabled = true,
  },
  ["xsel"] = {
    name = "xsel",
    copy = {
      ["+"] = { "xsel", "--nodetach", "-i", "-b" },
      ["*"] = { "xsel", "--nodetach", "-i", "-p" },
    },
    paste = {
      ["+"] = { "xsel", "-o", "-b" },
      ["*"] = { "xsel", "-o", "-p" },
    },
    cache_enabled = true,
  },
}

return clipboards["{{ clipboard }}"]
