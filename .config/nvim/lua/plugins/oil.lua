return {
  'stevearc/oil.nvim',
  -- netrw is disabled, so oil has to be loaded eagerly for `nvim <dir>` to work.
  -- Upstream also advises against lazy-loading it.
  lazy = false,
  keys = {
    { '<leader>e', '<cmd>Oil<cr>', desc = 'Open Oil' },
  },
  opts = {},
}
