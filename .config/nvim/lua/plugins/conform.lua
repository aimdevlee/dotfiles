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
      -- Don't format when minifiles is open, since that triggers the "confirm without
      -- synchronization" message.
      if vim.g.minifiles_active then
        return nil
      end

      -- Skip formatting if triggered from my special save command.
      if vim.g.skip_formatting then
        vim.g.skip_formatting = false
        return nil
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
