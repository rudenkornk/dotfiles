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
      "pylsp",
      "html",
      "jedi_language_server",
      "jsonls",
      "opencl_ls",
      "perlnavigator",
      "powershell_es",
      "texlab",
      "yamlls",
    }
    nvchad.capabilities.offsetEncoding = { "utf-16" }

    for _, lsp in ipairs(servers) do
      lspconfig[lsp].setup({
        on_attach = function(client, bufnr)
          nvchad.on_attach(client, bufnr)
          require("illuminate").on_attach(client)
        end,
        capabilities = nvchad.capabilities,
      })
    end
  end,
}
