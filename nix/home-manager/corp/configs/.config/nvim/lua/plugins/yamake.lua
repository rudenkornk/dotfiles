local repo = vim.fs.normalize("~/projects/arcadia/devtools/ide/tree-sitter-yamake")
local parser = vim.fs.joinpath(vim.fn.stdpath("state"), "tree-sitter", "yamake.so")

local function build()
  local generated = vim.uv.fs_stat(vim.fs.joinpath(repo, "src", "parser.c"))
  local built = vim.uv.fs_stat(parser)
  if built and generated and built.mtime.sec >= generated.mtime.sec then
    return true
  end
  vim.fn.mkdir(vim.fs.dirname(parser), "p")
  local result = vim.system({ "tree-sitter", "build", "--output", parser, repo }):wait()
  if result.code ~= 0 then
    vim.notify(result.stderr, vim.log.levels.ERROR, { title = "tree-sitter-yamake" })
    return false
  end
  return true
end

return {
  {
    dir = repo,
    enabled = vim.fn.isdirectory(repo) == 1,
    ft = "yamake",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    init = function()
      vim.filetype.add({
        filename = {
          ["ya.make"] = "yamake",
          ["ya.make.ext"] = "yamake",
          ["ya.inc"] = "yamake",
          ["include.inc"] = "yamake",
          ["recipe.inc"] = "yamake",
          ["dependency_management.inc"] = "yamake",
        },
      })
    end,
    config = function()
      if not build() then
        return
      end
      vim.treesitter.language.add("yamake", { path = parser })
      -- LazyVim gates highlighting, folds, indents and textobjects on the parsers it finds in the
      -- `nvim-treesitter` install directory, which is a read-only nix store path and has no `yamake`.
      LazyVim.treesitter.get_installed()["yamake"] = true
    end,
  },
}
