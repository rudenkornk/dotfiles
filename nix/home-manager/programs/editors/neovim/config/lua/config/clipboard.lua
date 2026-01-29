-- https://github.com/LazyVim/LazyVim/blob/25abbf546d564dc484cf903804661ba12de45507/lua/lazyvim/config/options.lua#L57

if vim.env.SSH_TTY then
  return ""
end

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
      ["+"] = { "xsel", "--nodetach", "--input", "--clipboard" },
      ["*"] = { "xsel", "--nodetach", "--input", "--primary" },
    },
    paste = {
      ["+"] = { "xsel", "--output", "--clipboard" },
      ["*"] = { "xsel", "--output", "--primary" },
    },
    cache_enabled = true,
  },
  ["wl-clipboard"] = {
    name = "wl-clipboard",
    copy = {
      -- "--trim-newline" removes extra newline before pasted text.
      ["+"] = { "wl-copy", "--trim-newline", "--foreground" },
      ["*"] = { "wl-copy", "--trim-newline", "--foreground" },
    },
    paste = {
      -- "--no-newline" removes extra newline after pasted text.
      ["+"] = { "wl-paste", "--no-newline" },
      ["*"] = { "wl-paste", "--no-newline" },
    },
    cache_enabled = true,
  },
}

return clipboards[require("config.this_clipboard")]
