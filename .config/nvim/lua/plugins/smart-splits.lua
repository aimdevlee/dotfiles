return {
  'mrjones2014/smart-splits.nvim',
  config = function()
    require('smart-splits').setup({})

    local keymap = vim.keymap
    -- move between pane in nvim or tmux or terminal multiplexer
    keymap.set('n', '<C-k>', require('smart-splits').move_cursor_up, { desc = 'Move to Upper Window (Tmux aware)' })
    keymap.set('n', '<C-j>', require('smart-splits').move_cursor_down, { desc = 'Move to Lower Window (Tmux aware)' })
    keymap.set('n', '<C-h>', require('smart-splits').move_cursor_left, { desc = 'Move to Left Window (Tmux aware)' })
    keymap.set('n', '<C-l>', require('smart-splits').move_cursor_right, { desc = 'Move to Right Window (Tmux aware)' })
    keymap.set('n', '<C-Up>', require('smart-splits').move_cursor_up, { desc = 'Move to Upper Window (Tmux aware)' })

    -- navigate with arrow keys for colemak users
    keymap.set(
      'n',
      '<C-Down>',
      require('smart-splits').move_cursor_down,
      { desc = 'Move to Lower Window (Tmux aware)' }
    )
    keymap.set('n', '<C-Left>', require('smart-splits').move_cursor_left, { desc = 'Move to Left Window (Tmux aware)' })
    keymap.set(
      'n',
      '<C-Right>',
      require('smart-splits').move_cursor_right,
      { desc = 'Move to Right Window (Tmux aware)' }
    )
  end,
}
