require('core.options')
require('core.keymaps')
require('core.autocmds')
require('core.lsp')

vim.pack.add({
  { src = 'https://github.com/nvim-lualine/lualine.nvim' },
  { src = 'https://github.com/rose-pine/neovim', name = 'rose-pine' },
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'master' },
  { src = 'https://github.com/mrjones2014/smart-splits.nvim' },
  { src = 'https://github.com/tpope/vim-fugitive' },
  { src = 'https://github.com/lewis6991/gitsigns.nvim' },
  { src = 'https://github.com/echasnovski/mini.nvim' },
})

require('plugins.rose-pine')
require('plugins.blink')
require('plugins.lualine')
require('plugins.treesitter')
require('plugins.conform')
require('plugins.mini')
require('plugins.smart-splits')
require('plugins.stickybuf')
require('plugins.gitsigns')

require('vim._extui').enable({})
