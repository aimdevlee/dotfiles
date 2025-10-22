local library = vim.tbl_filter(function(d)
  return not d:match(vim.fn.stdpath('config'))
end, vim.api.nvim_get_runtime_file('', true))

local servers = {
  eslint = {},
  tsgo = {},
  lua_ls = {
    runtime = {
      version = 'LuaJIT',
      path = { 'lua/?.lua', 'lua/?/init.lua' },
    },
    format = {
      enable = false,
    },
    diagnostics = {
      globals = { 'vim' },
    },
    workspace = {
      checkThirdParty = false,
      library = vim.tbl_extend('keep', {
        '$VIMRUNTIME',
      }, library),
    },
  },
  ruby_lsp = {
    init_options = {
      formatter = 'auto',
    },
    capabilities = {
      general = { positionEncodings = 'utf-16' },
    },
  },
  sorbet = {
    cmd = { 'bundle', 'exec', 'srb', 'typecheck', '--lsp' },
    on_attach = function(client, _)
      if client.server_capabilities.sorbetShowSymbolProvider then
        vim.api.nvim_create_user_command('CopySymbolToClipboard', function()
          -- Get the current cursor position (1-based line, 0-based column)
          local line, col = unpack(vim.api.nvim_win_get_cursor(0))
          local params = {
            textDocument = { uri = 'file://' .. vim.api.nvim_buf_get_name(0) },
            -- Adjusting line number to match 0-based indexing for Sorbet's request.
            -- ref. https://github.com/sorbet/sorbet/blob/c73f3beb911f551e789210190c087006f46614f2/main/lsp/json_types.cc#L191
            position = { line = line - 1, character = col },
          }
          local result = client.request_sync('sorbet/showSymbol', params, 3000)

          -- copy symbol to clipboard
          for _, response in pairs(result) do
            if response.name then
              vim.fn.setreg('+', response.name)
            end
          end
        end, {})
      end
    end,
  },
}

for server_name, config in pairs(servers) do
  if next(config) then
    vim.lsp.config(server_name, config)
  end
end

vim.lsp.enable(vim.tbl_keys(servers))

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp_keymaps', { clear = true }),
  callback = function(event)
    if not event.data or not event.data.client_id then
      return
    end

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client then
      -- Formatting with gq (native vim keybind for formatting)
      if client:supports_method('textDocument/formatting') then
        vim.keymap.set('n', '<leader>lf', function()
          vim.lsp.buf.format({ async = true })
        end, { desc = 'Format Buffer' })
      end

      if client:supports_method('textDocument/inlayHint') then
        vim.keymap.set('n', '<leader>lh', function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }), { bufnr = event.buf })
        end, { desc = 'Toggle Inlay Hints' })
      end
    end
  end,
})

vim.keymap.set('n', '<leader>li', ':LspInfo', { desc = 'Lsp Info' })
vim.keymap.set('n', '<leader>ll', ':LspLog', { desc = 'Lsp Log' })
