return {
  'OXY2DEV/markview.nvim',
  lazy = false,
  config = function()
    local presets = require('markview.presets')

    require('markview').setup({
      preview = {
        modes = { 'i', 'n', 'no', 'c' },
        hybrid_modes = { 'i' },
      },
      markdown = {
        headings = presets.headings.marker,
      },
    })
  end,
}
