require("nvchad.configs.lspconfig").defaults()

local servers = { "html", "cssls", "ts_ls", "pyright", "jsonls", "yamlls", "taplo" }
vim.lsp.enable(servers)
