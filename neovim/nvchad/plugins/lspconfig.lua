return {
  config = function()
    local nvchad = require("plugins.configs.lspconfig")

    local lspconfig = require("lspconfig")
    local servers = {
      "bashls",
      "clangd",
      "cmake",
      "cssls",
      "dockerls",
      "dotls",
      "html",
      "jedi_language_server",
      "jsonls",
      "opencl_ls",
      "perlnavigator",
      "powershell_es",
      "pylsp",
      "texlab",
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
      lspconfig[lsp].setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = settings,
      })
    end
  end,
}
