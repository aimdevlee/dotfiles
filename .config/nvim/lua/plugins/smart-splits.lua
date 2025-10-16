local smart_splits = require('smart-splits')

vim.keymap.set('n', '<C-k>', smart_splits.move_cursor_up, { desc = 'Move to Upper Window (Tmux aware)' })
vim.keymap.set('n', '<C-j>', smart_splits.move_cursor_down, { desc = 'Move to Lower Window (Tmux aware)' })
vim.keymap.set('n', '<C-h>', smart_splits.move_cursor_left, { desc = 'Move to Left Window (Tmux aware)' })
vim.keymap.set('n', '<C-l>', smart_splits.move_cursor_right, { desc = 'Move to Right Window (Tmux aware)' })

smart_splits.setup({
  at_edge = 'stop',
})
