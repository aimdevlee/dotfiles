return {
  'folke/persistence.nvim',
  event = 'BufReadPre',
  keys = {
    {
      '<leader>R',
      '<cmd>wall | restart lua require("persistence").load({last=true})<CR>',
      desc = 'Restart Neovim',
      mode = { 'n', 'v', 'x' },
    },
  },
  config = function()
    require('persistence').setup()
  end,
}
