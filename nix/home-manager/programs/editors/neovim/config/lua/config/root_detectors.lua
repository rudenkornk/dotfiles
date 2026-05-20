local M = {}

-- `LazyVim` defaults for `<leader><space>` find files and `<leader>/` live grep open in a  "root" directory.
-- This `root` directory has a rather complicated algorithm,
-- which defaults to `{ "lsp", { ".git", "lua" }, "cwd" }` and does not work for me well.
-- For example, in cases with nested projects inside one repo, `lsp` detector correctly recognizes
-- root of each sub-project, whereas I need a root of entire project.
--
-- That could be replaced with smth like `{ ".git", "cwd" }` detectors, but they act a bit inconsistent.
--   * If opening some external file (i.e. ~/.gitconfig) is inside git dir, then root is set to that external project.
--   * But if external file is not inside git dir, LazyVim opens cwd (i.e. where editor was open).
--
-- These helpers try to make things more consistent.
-- `buffer_root()` returns either git root of the buffer or its parent directory.
-- `cwd_root()` returns cwd git root or just cwd if .git is not found.
--
-- See:
-- https://github.com/LazyVim/LazyVim/blob/25abbf546d564dc484cf903804661ba12de45507/lua/lazyvim/config/options.lua#L33
-- https://github.com/LazyVim/LazyVim/blob/25abbf546d564dc484cf903804661ba12de45507/lua/lazyvim/util/root.lua
-- https://github.com/LazyVim/lazyvim.github.io/blob/5cc96146d96bb61ad915088bc3eec4151643cd6f/docs/news.md?plain=1#L258

M.cwd_root = function(buf)
  local cwd = vim.uv.cwd() or ""
  local cwd_git = vim.fs.find(".git", { path = cwd, upward = true })[1]
  local cwd_root_ = cwd_git and vim.fn.fnamemodify(cwd_git, ":h") or cwd
  return cwd_root_
end

M.buffer_root = function(buf)
  local bufpath = vim.api.nvim_buf_get_name(buf)
  if bufpath == "" then
    return nil
  end

  -- Try to find .git root of the buf's directory.
  local buf_git = vim.fs.find(".git", { path = vim.fn.fnamemodify(bufpath, ":h"), upward = true })[1]
  if buf_git then
    return vim.fn.fnamemodify(buf_git, ":h")
  end

  -- Fallback to parent directory of buf.
  return vim.fn.fnamemodify(bufpath, ":h")
end

return M
