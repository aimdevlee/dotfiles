return {
  {
    'zbirenbaum/copilot.lua',
    event = 'InsertEnter',
    opts = {
      panel = { enabled = false },
      suggestion = {
        auto_trigger = true,
        hide_during_completion = false,
        keymap = {
          accept = '<C-l>',
          accept_word = '<M-w>',
          accept_line = '<M-l>',
          next = '<M-]>',
          prev = '<M-[>',
          dismiss = '<C-/>',
        },
      },
      filetypes = {
        markdown = true,
        yaml = true,
      },
      copilot_node_command = {
        'mise',
        'exec',
        'node@latest',
        '--',
        'node',
      },
    },
  },
}
