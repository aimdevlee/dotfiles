-- herdr-nvim-nav: Ctrl+h/j/k/l across Neovim splits and herdr/tmux panes.
-- The plugin also depends on vim-tmux-navigator for the tmux fallback (I run
-- Neovim under both herdr and tmux). herdr-only setups can drop that dep and
-- pass with_tmux = false.
return {
  'aimdevlee/herdr-nvim-nav',
  dependencies = { 'christoomey/vim-tmux-navigator' },
  lazy = false,
  config = function()
    require('herdr-nvim-nav').setup()
  end,
}
