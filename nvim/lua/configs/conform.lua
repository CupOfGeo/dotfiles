local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    css = { "prettier" },
    html = { "prettier" },
    sh = { "shfmt" },
    python = { "ruff_format" },
    json = {"jq"},
  },

  default_format_opts = {
    lsp_format = "fallback",
  },
}

return options
