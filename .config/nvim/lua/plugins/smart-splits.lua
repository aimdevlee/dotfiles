return {
  'mrjones2014/smart-splits.nvim',
  config = function()
    require('smart-splits').setup({})

    local keymap = vim.keymap
    -- move between pane in nvim or tmux or terminal multiplexer
    keymap.set('n', '<C-k>', require('smart-splits').move_cursor_up)
    keymap.set('n', '<C-j>', require('smart-splits').move_cursor_down)
    keymap.set('n', '<C-h>', require('smart-splits').move_cursor_left)
    keymap.set('n', '<C-l>', require('smart-splits').move_cursor_right)
    keymap.set('n', '<C-Up>', require('smart-splits').move_cursor_up)

    -- navigate with arrow keys for colemak users
    keymap.set('n', '<C-Left>', require('smart-splits').move_cursor_left)
    keymap.set('n', '<C-Down>', require('smart-splits').move_cursor_down)
    keymap.set('n', '<C-Up>', require('smart-splits').move_cursor_up)
    keymap.set('n', '<C-Right>', require('smart-splits').move_cursor_right)
  end,
}
