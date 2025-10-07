---@type vim.lsp.Config
return {
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
}
