return {
  'folke/lazydev.nvim',
  ft = 'lua', -- only load on lua files
  opts = {
    library = {
      -- See the configuration section for more details
      -- Load luvit types when the `vim.uv` word is found
      -- { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      -- uncomment to add all plugins under your lazy data directory
      -- os.getenv('XDG_DATA_HOME') .. '/nvim/lazy/',
      'lazy.nvim',
      { path = 'snacks.nvim', words = { 'Snacks' } },
    },
  },
}
