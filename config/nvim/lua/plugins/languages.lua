-- Multi-language support for Python, Node, Rust, Go, Java
return {
  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Python
        pyright = {},
        ruff_lsp = {},

        -- JavaScript/TypeScript
        ts_ls = {},
        eslint = {},

        -- Rust
        rust_analyzer = {
          settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
              },
              checkOnSave = {
                command = "clippy",
              },
            },
          },
        },

        -- Go
        gopls = {
          settings = {
            gopls = {
              analyses = {
                unusedparams = true,
              },
              staticcheck = true,
            },
          },
        },

        -- Java
        jdtls = {},
      },
    },
  },

  -- Treesitter for syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "python",
        "javascript",
        "typescript",
        "tsx",
        "rust",
        "go",
        "java",
        "lua",
        "vim",
        "json",
        "yaml",
        "toml",
        "markdown",
      },
    },
  },

  -- Mason for managing LSP servers
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        -- Python
        "pyright",
        "ruff-lsp",
        "black",
        "isort",

        -- JavaScript/TypeScript
        "typescript-language-server",
        "eslint-lsp",
        "prettier",

        -- Rust
        "rust-analyzer",

        -- Go
        "gopls",
        "gofumpt",
        "goimports",

        -- Java
        "jdtls",

        -- Formatters and linters
        "stylua",
      },
    },
  },

  -- Formatting
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "black", "isort" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        rust = { "rustfmt" },
        go = { "gofumpt", "goimports" },
        java = { "google-java-format" },
        lua = { "stylua" },
      },
    },
  },

  -- Linting
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        python = { "ruff" },
        javascript = { "eslint" },
        typescript = { "eslint" },
        go = { "golangcilint" },
      },
    },
  },
}