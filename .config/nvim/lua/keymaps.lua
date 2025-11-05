local map = vim.keymap.set

-- Better up/down (use gj/gk for wrapped lines)
map({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
map({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })

-- Move to window using the <ctrl> hjkl keys
-- Note: Disabled in favor of smart-splits.nvim (Tmux-aware navigation)
-- map('n', '<C-h>', '<C-w>h', { desc = 'Go to Left Window', remap = true })
-- map('n', '<C-j>', '<C-w>j', { desc = 'Go to Lower Window', remap = true })
-- map('n', '<C-k>', '<C-w>k', { desc = 'Go to Upper Window', remap = true })
-- map('n', '<C-l>', '<C-w>l', { desc = 'Go to Right Window', remap = true })

map('n', '<C-Up>', '<cmd>resize +2<cr>', { desc = 'Increase Window Height' })
map('n', '<C-Down>', '<cmd>resize -2<cr>', { desc = 'Decrease Window Height' })
map('n', '<C-Left>', '<cmd>vertical resize -2<cr>', { desc = 'Decrease Window Width' })
map('n', '<C-Right>', '<cmd>vertical resize +2<cr>', { desc = 'Increase Window Width' })

map('n', '<A-j>', '<cmd>m .+1<cr>==', { desc = 'Move Line Down' })
map('n', '<A-k>', '<cmd>m .-2<cr>==', { desc = 'Move Line Up' })
map('i', '<A-j>', '<esc>:m .+1<cr>==gi', { desc = 'Move Line Down' })
map('i', '<A-k>', '<esc>:m .-2<cr>==gi', { desc = 'Move Line Up' })
map('v', '<A-j>', ":m '>+1<cr>gv=gv", { desc = 'Move Selection Down' })
map('v', '<A-k>', ":m '<-2<cr>gv=gv", { desc = 'Move Selection Up' })

map('n', '<S-h>', '<cmd>bprevious<cr>', { desc = 'Prev Buffer' })
map('n', '<S-l>', '<cmd>bnext<cr>', { desc = 'Next Buffer' })
map('n', '[b', '<cmd>bprevious<cr>', { desc = 'Prev Buffer' })
map('n', '<leader>bd', '<cmd>bdelete<cr>', { desc = 'Delete Buffer' })
map('n', ']b', '<cmd>bnext<cr>', { desc = 'Next Buffer' })

-- Clear search with <esc>
map({ 'i', 'n' }, '<esc>', '<cmd>noh<cr><esc>', { desc = 'Escape and Clear hlsearch' })

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
-- expr = true allows the mapping to be evaluated as an expression
map('n', 'n', "'Nn'[v:searchforward].'zv'", { expr = true, desc = 'Next Search Result' })
map('x', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next Search Result' })
map('o', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next Search Result' })
map('n', 'N', "'nN'[v:searchforward].'zv'", { expr = true, desc = 'Prev Search Result' })
map('x', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev Search Result' })
map('o', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev Search Result' })

-- https://github.com/mhinz/vim-galore?tab=readme-ov-file#quickly-edit-your-macros
map(
  'n',
  '<leader>m',
  ":<c-u><c-r><c-r>='let @'. v:register .' = '. string(getreg(v:register))<cr><c-f><left>",
  { desc = 'Edit macro' }
)

-- Add undo break-points
map('i', ',', ',<c-g>u')
map('i', '.', '.<c-g>u')
map('i', ';', ';<c-g>u')

-- Better indenting (keep visual selection after indent)
map('v', '<', '<gv')
map('v', '>', '>gv')

map('n', 'gco', 'o<esc>Vcx<esc>:normal gcc<cr>fxa<bs>', { desc = 'Add Comment Below' })
map('n', 'gcO', 'O<esc>Vcx<esc>:normal gcc<cr>fxa<bs>', { desc = 'Add Comment Above' })

map('n', '<leader>fn', '<cmd>enew<cr>', { desc = 'New File' })

map('n', '<leader>-', '<C-w>s', { desc = 'Split Window Below' })
map('n', '<leader>|', '<C-w>v', { desc = 'Split Window Right' })

map('n', '<leader><tab><tab>', '<cmd>tabnew<cr>', { desc = 'New Tab' })
map('n', '<leader><tab>d', '<cmd>tabclose<cr>', { desc = 'Close Tab' })
map('n', '<leader><tab>]', '<cmd>tabnext<cr>', { desc = 'Next Tab' })
map('n', '<leader><tab>[', '<cmd>tabprevious<cr>', { desc = 'Previous Tab' })

map('n', '<leader>yp', ":let @+=expand('%:.')<cr>", { desc = 'Copy relative path' })
map('n', '<leader>yP', '<cmd>let @+=@%<cr>', { desc = 'Copy absolute path' })

map({ 'n' }, '<leader>cx', '<cmd>.lua<cr>', { desc = 'Execute lua script' })
map({ 'v', 'x' }, '<leader>cx', ":'<,'>.lua<cr>", { desc = 'Execute selected lua script' })
map({ 'n' }, '<leader>xq', '<cmd>copen<CR>', { desc = 'Open quickfix', silent = true })
map({ 'n' }, '<leader>xl', '<cmd>lopen<CR>', { desc = 'Open loclist', silent = true })
map({ 'n', 'v', 'x' }, '<leader>R', '<cmd>restart<CR>', { desc = 'Restart Neovim' })
map({ 'n' }, '<leader>w', '<cmd>update<CR>', { desc = 'Write the current buffer.' })
map({ 'n' }, '<leader>q', '<cmd>quit<CR>', { desc = 'Quit the current buffer.' })
map({ 'n' }, '<leader>Q', '<cmd>wqa<CR>', { desc = 'Quit all buffers and write.' })
