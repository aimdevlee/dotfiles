local map = vim.keymap.set

-- Keymap Options:
-- desc: Description shown in which-key or :map
-- expr: Expression mapping (evaluated to get the actual command)
-- silent: Don't show command in command line
-- remap: Allow remapping (use existing mappings)
-- buffer: Buffer-local mapping (number or true for current)
-- nowait: Don't wait for more key input

-- Better up/down (use gj/gk for wrapped lines)
map({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
map({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })

-- Move to window using the <ctrl> hjkl keys
map('n', '<C-h>', '<C-w>h', { desc = 'Go to Left Window', remap = true })
map('n', '<C-j>', '<C-w>j', { desc = 'Go to Lower Window', remap = true })
map('n', '<C-k>', '<C-w>k', { desc = 'Go to Upper Window', remap = true })
map('n', '<C-l>', '<C-w>l', { desc = 'Go to Right Window', remap = true })

-- Resize window using <ctrl> arrow keys
map('n', '<C-Up>', '<cmd>resize +2<cr>', { desc = 'Increase Window Height' })
map('n', '<C-Down>', '<cmd>resize -2<cr>', { desc = 'Decrease Window Height' })
map('n', '<C-Left>', '<cmd>vertical resize -2<cr>', { desc = 'Decrease Window Width' })
map('n', '<C-Right>', '<cmd>vertical resize +2<cr>', { desc = 'Increase Window Width' })

-- Move Lines
map('n', '<A-j>', '<cmd>m .+1<cr>==', { desc = 'Move Line Down' })
map('n', '<A-k>', '<cmd>m .-2<cr>==', { desc = 'Move Line Up' })
map('i', '<A-j>', '<esc><cmd>m .+1<cr>==gi', { desc = 'Move Line Down' })
map('i', '<A-k>', '<esc><cmd>m .-2<cr>==gi', { desc = 'Move Line Up' })
map('v', '<A-j>', ":m '>+1<cr>gv=gv", { desc = 'Move Selection Down' })
map('v', '<A-k>', ":m '<-2<cr>gv=gv", { desc = 'Move Selection Up' })

-- Buffers
map('n', '<S-h>', '<cmd>bprevious<cr>', { desc = 'Prev Buffer' })
map('n', '<S-l>', '<cmd>bnext<cr>', { desc = 'Next Buffer' })
map('n', '[b', '<cmd>bprevious<cr>', { desc = 'Prev Buffer' })
map('n', ']b', '<cmd>bnext<cr>', { desc = 'Next Buffer' })
map('n', '<leader>bb', '<cmd>e #<cr>', { desc = 'Switch to Other Buffer' })
map('n', '<leader>bd', '<cmd>bdelete<cr>', { desc = 'Delete Buffer' })
map('n', '<leader>bD', '<cmd>:bd<cr>', { desc = 'Delete Buffer and Window' })

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

-- Add undo break-points
map('i', ',', ',<c-g>u')
map('i', '.', '.<c-g>u')
map('i', ';', ';<c-g>u')

-- Keywordprg
map('n', '<leader>K', '<cmd>norm! K<cr>', { desc = 'Keywordprg' })

-- Better indenting (keep visual selection after indent)
map('v', '<', '<gv')
map('v', '>', '>gv')

-- Commenting
map('n', 'gco', 'o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>', { desc = 'Add Comment Below' })
map('n', 'gcO', 'O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>', { desc = 'Add Comment Above' })

-- Lazy
map('n', '<leader>l', '<cmd>Lazy<cr>', { desc = 'Lazy' })

-- New file
map('n', '<leader>fn', '<cmd>enew<cr>', { desc = 'New File' })

-- Quit
map('n', '<leader>qq', '<cmd>qa<cr>', { desc = 'Quit All' })

-- Windows (remap = true allows <c-w> mappings to work)
-- map("n", "<leader>w", "<c-w>", { desc = "Windows", remap = true })
map('n', '<leader>-', '<C-w>s', { desc = 'Split Window Below', remap = true })
map('n', '<leader>|', '<C-w>v', { desc = 'Split Window Right', remap = true })
map('n', '<leader>wd', '<C-w>c', { desc = 'Delete Window', remap = true })

-- Tabs
map('n', '<leader><tab>l', '<cmd>tablast<cr>', { desc = 'Last Tab' })
map('n', '<leader><tab>o', '<cmd>tabonly<cr>', { desc = 'Close Other Tabs' })
map('n', '<leader><tab>f', '<cmd>tabfirst<cr>', { desc = 'First Tab' })
map('n', '<leader><tab><tab>', '<cmd>tabnew<cr>', { desc = 'New Tab' })
map('n', '<leader><tab>]', '<cmd>tabnext<cr>', { desc = 'Next Tab' })
map('n', '<leader><tab>d', '<cmd>tabclose<cr>', { desc = 'Close Tab' })
map('n', '<leader><tab>[', '<cmd>tabprevious<cr>', { desc = 'Previous Tab' })

-- Copy paths
map('n', '<leader>yp', "<cmd>let @+=expand('%:.')<cr>", { desc = 'Copy relative path' })
map('n', '<leader>yP', '<cmd>let @+=@%<cr>', { desc = 'Copy absolute path' })
