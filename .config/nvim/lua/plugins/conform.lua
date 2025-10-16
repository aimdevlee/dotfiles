vim.pack.add({
  'https://github.com/stevearc/conform.nvim',
})

require('conform').setup({
  init = function()
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    vim.g.autoformat = true
  end,
  notify_on_error = false,
  notify_no_formatters = false,
  format_on_save = {
    timeout_ms = 5000,
    lsp_format = 'fallback', -- Use LSP formatting if conform formatter not available
  },
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
})
