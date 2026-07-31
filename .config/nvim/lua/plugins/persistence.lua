return {
  'folke/persistence.nvim',
  event = 'BufReadPre',
  keys = {
    {
      '<leader>R',
      '<cmd>wall | restart lua require("persistence").load({last=true})<CR>',
      desc = 'Restart Neovim',
      -- 'x', not 'v': 'v' would also bind this in Select mode, where <leader>
      -- is a literal space that should replace a snippet placeholder.
      mode = { 'n', 'x' },
    },
  },
  config = function()
    require('persistence').setup()
  end,
}
