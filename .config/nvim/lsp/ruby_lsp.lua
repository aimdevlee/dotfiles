---@type vim.lsp.Config
return {
  init_options = {
    formatter = 'auto',
  },
  capabilities = {
    general = { positionEncodings = 'utf-16' },
  },
}
