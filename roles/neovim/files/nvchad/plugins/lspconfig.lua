local manifest = require("custom.plugins.manifest")

return {
  commit = manifest["neovim/nvim-lspconfig"].commit,
  config = function()
    local nvchad = require("plugins.configs.lspconfig")

    local lspconfig = require("lspconfig")
    -- see https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
    local servers = {
      "ansiblels",
      "bashls",
      "clangd",
      "cmake",
      "cssls",
      "dockerls",
      "dotls",
      "eslint",
      "groovyls",
      "html",
      "jedi_language_server",
      "jsonls",
      "opencl_ls",
      "perlnavigator",
      "powershell_es",
      "sumneko_lua",
      "texlab",
      "vimls",
      "yamlls",
    }
    nvchad.capabilities.offsetEncoding = { "utf-16" }

    for _, lsp in ipairs(servers) do
      local on_attach = function(client, bufnr)
        nvchad.on_attach(client, bufnr)
        require("illuminate").on_attach(client)
      end
      local capabilities = nvchad.capabilities
      local settings = {}
      if lsp == "sumneko_lua" then
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
            workspace = {
              library = {
                [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
              },
              maxPreload = 100000,
              preloadFileSize = 10000,
            },
          },
        }
      end

      lspconfig[lsp].setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = settings,
      })
    end
  end,
}
