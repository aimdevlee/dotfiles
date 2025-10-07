require('conform').setup({
  init = function()
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    vim.g.autoformat = true
  end,
  notify_on_error = false,
  notify_no_formatters = false,
  format_on_save = {},
  formatters_by_ft = {
    ruby = { 'syntax_tree' },
    javascript = { 'prettier' },
    typescript = { 'prettier' },
    typescriptreact = { 'prettier' },
    toml = { 'taplo' },
    lua = { 'stylua' },
    yaml = { 'prettier' },
    ['_'] = { 'trim_whitespace', 'trim_newlines' },
  },
})
