return {
  'stevearc/conform.nvim',
  event = 'BufWritePre',
  cmd = { 'ConformInfo' },
  keys = {},
  ---@module "conform"
  ---@type conform.setupOpts
  opts = {
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
      vim.g.autoformat = true
    end,
    notify_on_error = false,
    notify_no_formatters = false,
    format_on_save = function()
      if vim.g.disable_autoformat then
        return
      end

      return {}
    end,
    formatters_by_ft = {
      ruby = { 'syntax_tree' },
      javascript = { 'prettier' },
      typescript = { 'prettier' },
      typescriptreact = { 'prettier' },
      javascriptreact = { 'prettier' },
      toml = { 'taplo' },
      lua = { 'stylua' },
      yaml = { 'prettier' },
      python = { 'ruff_format', 'ruff_organize_imports' },
      go = { 'goimports', 'gofmt' },
      rust = { 'rustfmt' },
      ['_'] = { 'trim_whitespace', 'trim_newlines' },
    },
  },
}
