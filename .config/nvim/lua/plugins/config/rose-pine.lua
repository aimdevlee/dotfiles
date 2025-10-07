require('rose-pine').setup({
  variant = 'moon',
  dark_variant = 'moon',
  dim_inactive_windows = false,
  highlight_groups = {
    Visual = { fg = 'text', bg = 'love' },
  },
  styles = {
    transparency = true,
  },
})

vim.cmd('colorscheme rose-pine-moon')
