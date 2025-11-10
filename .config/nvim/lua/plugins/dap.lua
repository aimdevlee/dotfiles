return {
  'mfussenegger/nvim-dap',
  dependencies = {
    {
      'igorlfs/nvim-dap-view',
      opts = {
        winbar = {
          sections = { 'watches', 'scopes', 'exceptions', 'breakpoints', 'threads', 'repl' },
        },
      },
    },
    {
      'theHamsta/nvim-dap-virtual-text',
      opts = { virt_text_pos = 'eol' },
    },
    { 'jbyuki/one-small-step-for-vimkind' },
  },
  config = function()
    local dap = require('dap')

    dap.configurations.lua = {
      {
        type = 'nlua',
        request = 'attach',
        name = 'Attach to running Neovim instance',
      },
    }

    dap.adapters.nlua = function(callback, config)
      callback({ type = 'server', host = config.host or '127.0.0.1', port = config.port or 8086 })
    end

    vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { noremap = true })
    vim.keymap.set('n', '<leader>dc', dap.continue, { noremap = true })
    vim.keymap.set('n', '<leader>do', dap.step_over, { noremap = true })
    vim.keymap.set('n', '<leader>di', dap.step_into, { noremap = true })

    vim.keymap.set('n', '<leader>dl', function()
      require('osv').launch({ port = 8086 })
    end, { noremap = true })

    vim.keymap.set('n', '<leader>dw', function()
      local widgets = require('dap.ui.widgets')
      widgets.hover()
    end)

    vim.keymap.set('n', '<leader>df', function()
      local widgets = require('dap.ui.widgets')
      widgets.centered_float(widgets.frames)
    end)
  end,
}
