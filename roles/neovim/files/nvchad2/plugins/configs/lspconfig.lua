local config = function()
  local nvchad = require("plugins.configs.lspconfig")

  local lspconfig = require("lspconfig")
  -- see https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
  local servers = {
    "ansiblels",
    "arduino_language_server",
    "awk_ls",
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
    "lua_ls",
    "opencl_ls",
    "ruby_ls",
    "rust_analyzer",
    "salt_ls",
    "sqlls",
    "texlab",
    "vimls",
    -- "yamlls", -- TODO: make it less annoying
    -- "asm_lsp", -- not working
    -- "perlnavigator", -- not working
    -- "powershell_es", -- not working
  }
  nvchad.capabilities.offsetEncoding = { "utf-16" }

  for _, lsp in ipairs(servers) do
    local on_attach = function(client, bufnr)
      nvchad.on_attach(client, bufnr)
      require("illuminate").on_attach(client)
    end
    local capabilities = nvchad.capabilities
    local settings = {}
    if lsp == "lua_ls" then
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
end

return config
