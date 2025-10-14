return {
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    config = function()
      require('plugins.config.rose-pine')
    end,
  },
  {
    'stevearc/oil.nvim',
    lazy = false,
    config = function()
      require('plugins.config.oil')
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      require('plugins.config.treesitter')
    end,
  },
  {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
    config = function()
      require('plugins.config.conform')
    end,
  },
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('plugins.config.gitsigns')
    end,
  },
  {
    'folke/persistence.nvim',
    event = 'BufReadPre',
    config = function()
      require('plugins.config.persistence')
    end,
  },
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    config = function()
      require('plugins.config.which-key')
    end,
  },
  {
    'mrjones2014/smart-splits.nvim',
    config = function()
      require('plugins.config.smart-splits')
    end,
  },
  {
    'echasnovski/mini.ai',
    event = 'VeryLazy',
    config = function()
      require('plugins.config.mini-ai')
    end,
  },
  {
    'echasnovski/mini.pairs',
    event = 'InsertEnter',
    config = function()
      require('plugins.config.mini-pairs')
    end,
  },
  {
    'echasnovski/mini.surround',
    config = function()
      require('plugins.config.mini-surround')
    end,
  },
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    config = function()
      require('plugins.config.snacks')
    end,
  },
  {
    'stevearc/stickybuf.nvim',
    config = function()
      require('plugins.config.stickybuf')
    end,
  },
  {
    'nvim-lualine/lualine.nvim',
    config = function()
      require('plugins.config.lualine')
    end,
  },
  {
    'nvim-tree/nvim-web-devicons',
  },
  {
    'neovim/nvim-lspconfig',
  },
  {
    'saghen/blink.cmp',
    dependencies = { 'rafamadriz/friendly-snippets' },
    version = '1.*',
    opts = {
      keymap = { preset = 'default' },

      appearance = {
        nerd_font_variant = 'mono',
      },

      completion = { documentation = { auto_show = false } },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },

      fuzzy = { implementation = 'prefer_rust_with_warning' },
    },
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
  },
}
