return {
  {
    "stevearc/conform.nvim",
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim", "lua", "vimdoc",
        "html", "css", "javascript", "typescript", "tsx",
        "markdown", "markdown_inline",
        "python", "bash",
        "json", "yaml", "toml",
      },
    },
  },

  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = "VeryLazy",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-tool-installer").setup {
        ensure_installed = {
          "lua-language-server",
          "stylua",
          "css-lsp",
          "html-lsp",
          "typescript-language-server",
          "prettier",
          "pyright",
          "ruff",
          "shfmt",
          "json-lsp",
          "yaml-language-server",
          "taplo",
        },
        run_on_start = true,
      }
    end,
  },
}
