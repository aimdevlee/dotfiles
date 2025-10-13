-- Only set non-default LSP keymaps
local function on_attach(client, bufnr)
  local function map(mode, lhs, rhs, opts)
    opts = opts or {}
    opts.buffer = bufnr
    vim.keymap.set(mode, lhs, rhs, opts)
  end

  -- Formatting with gq (native vim keybind for formatting)
  if client:supports_method('textDocument/formatting') then
    map('n', 'gq', function()
      vim.lsp.buf.format({ async = true })
    end, { desc = 'Format Buffer' })
  end

  -- Inlay hints toggle
  if client:supports_method('textDocument/inlayHint') then
    map('n', '<leader>ih', function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
    end, { desc = 'Toggle Inlay Hints' })
  end
end

-- LSP management commands
vim.keymap.set('n', '<leader>li', '<cmd>LspInfo<cr>', { desc = 'Lsp Info' })
vim.keymap.set('n', '<leader>lr', '<cmd>LspRestart<cr>', { desc = 'Lsp Restart' })

-- Setup autocmd to attach keymaps when LSP attaches
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp_keymaps', { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client then
      on_attach(client, event.buf)
    end
  end,
})

-- Set up LSP servers.
vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
  once = true,
  callback = function()
    local lsp_path = vim.fn.stdpath('config') .. '/lsp'
    local files = vim.fn.readdir(lsp_path)

    -- Load each LSP config file and register it
    for _, file in ipairs(files) do
      if file:match('%.lua$') then
        local server_name = vim.fn.fnamemodify(file, ':t:r')
        local config_path = lsp_path .. '/' .. file
        local config = dofile(config_path)

        if config and type(config) == 'table' then
          vim.lsp.config(server_name, config)
        end
      end
    end

    -- Enable all loaded servers
    local server_configs = vim
      .iter(files)
      :map(function(file)
        return vim.fn.fnamemodify(file, ':t:r')
      end)
      :totable()
    vim.lsp.enable(server_configs)
  end,
})
