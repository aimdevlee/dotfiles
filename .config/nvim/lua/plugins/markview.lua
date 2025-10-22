return {
  'OXY2DEV/markview.nvim',
  lazy = false,
  config = function()
    require('markview').setup({
      preview = {
        modes = { 'i', 'n', 'no', 'c' },
        hybrid_modes = { 'i' },
      },
    })
  end,
}
