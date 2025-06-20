-- Conform Code Formatting Configuration
return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>cF",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = { "n", "v" },
      desc = "Format Injected Langs",
    },
  },
  config = function()
    local opts = {
      notify_on_error = false,
      format_on_save = function(_)
        return {
          timeout_ms = 1000,
        }
      end,
      formatters_by_ft = {
        lua = { "stylua" },
        ruby = { "syntax_tree" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        toml = { "taplo" },
      },
    }
    require("conform").setup(opts)
  end,
}