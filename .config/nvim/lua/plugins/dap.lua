return {
  'mfussenegger/nvim-dap',
  keys = {
    -- stylua: ignore start
    { '<space>dc', function() require('dap').continue() end, desc = 'DAP Continue' },
    { '<space>dr', function() require('dap').repl.toggle() end, desc = 'DAP Toggle REPL' },
    { '<space>db', function() require('dap').toggle_breakpoint() end, desc = 'DAP Toggle Breakpoint' },
    { '<space>dso', function() require('dap').step_over() end, desc = 'DAP Step Over' },
    { '<space>dsi', function() require('dap').step_into() end, desc = 'DAP Step Into' },
    { '<space>drl', function() require('dap').run_last() end, desc = 'DAP Run Last' },
    { '<space>dq', function() require('dap').terminate() end, desc = 'DAP Terminate' },
    -- stylua: ignore end
  },
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
  },
}
