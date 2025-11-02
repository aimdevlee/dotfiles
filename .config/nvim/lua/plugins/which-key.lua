return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  config = function()
    require('which-key').setup({
      preset = 'modern',
      icons = {
        mappings = false,
      },
      spec = {
        { '<leader>c', group = '+code' },
        { '<leader>f', group = '+file/find' },
        { '<leader>g', group = '+git' },
        { '<leader>gh', group = '+git hunk' },
        { '<leader>l', group = '+lsp' },
        { '<leader>s', group = '+search' },
        { '<leader>b', group = '+buffers' },
        { '<leader>t', group = 'toggle' },
        { '<leader>x', group = 'diagnostics/quickfix' },
        { '[', group = 'prev' },
        { ']', group = 'next' },
        { 'g', group = 'goto' },
      },
    })
  end,
}
