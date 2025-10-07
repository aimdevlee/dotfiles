local function augroup(name)
  return vim.api.nvim_create_augroup('nvim_' .. name, { clear = true })
end

-- ========================================
-- File Management
-- ========================================

-- Check if we need to reload the file when it changed
-- Example: File edited in another program gets reloaded when you focus Neovim
vim.api.nvim_create_autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  group = augroup('checktime'),
  callback = function()
    if vim.o.buftype ~= 'nofile' then
      vim.cmd('checktime')
    end
  end,
})

-- Auto-reload files changed outside of Neovim
-- Example: Git checkout in another terminal updates buffer automatically
vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
  group = augroup('auto_reload'),
  callback = function()
    if vim.fn.getcmdwintype() == '' then
      vim.cmd('checktime')
    end
  end,
})

-- Go to last location when opening a buffer
-- Example: Opening a file positions cursor where you left off
vim.api.nvim_create_autocmd('BufReadPost', {
  group = augroup('last_loc'),
  callback = function(event)
    local exclude = { 'gitcommit' }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then
      return
    end
    vim.b[buf].lazyvim_last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Auto create dir when saving a file
-- Example: Save ~/new/dir/file.txt creates directories automatically
vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
  group = augroup('auto_create_dir'),
  callback = function(event)
    if event.match:match('^%w%w+:[\\/][\\/]') then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
  end,
})

-- ========================================
-- Visual Feedback
-- ========================================

-- Highlight on yank
-- Example: Briefly highlights text when you copy it
vim.api.nvim_create_autocmd('TextYankPost', {
  group = augroup('highlight_yank'),
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})

-- Show cursor line only in active window
-- Example: Cursorline follows your active window
vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
  group = augroup('cursor_line_active'),
  callback = function()
    vim.opt_local.cursorline = true
  end,
})

vim.api.nvim_create_autocmd({ 'WinLeave', 'BufLeave' }, {
  group = augroup('cursor_line_inactive'),
  callback = function()
    vim.opt_local.cursorline = false
  end,
})

-- Highlight trailing whitespace (except when typing)
-- Example: Shows trailing spaces in red, but not while you're typing
vim.api.nvim_create_autocmd('InsertEnter', {
  group = augroup('trailing_space_hide'),
  pattern = '*',
  callback = function()
    vim.opt_local.listchars:remove('trail')
  end,
})

vim.api.nvim_create_autocmd('InsertLeave', {
  group = augroup('trailing_space_show'),
  pattern = '*',
  callback = function()
    vim.opt_local.listchars:append('trail:·')
  end,
})

-- ========================================
-- Window Management
-- ========================================

-- Resize splits if window got resized
-- Example: Terminal resize adjusts all split windows proportionally
vim.api.nvim_create_autocmd({ 'VimResized' }, {
  group = augroup('resize_splits'),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd('tabdo wincmd =')
    vim.cmd('tabnext ' .. current_tab)
  end,
})

-- Automatically balance window sizes
-- Example: Equal window sizes when opening/closing splits
vim.api.nvim_create_autocmd({ 'WinNew', 'WinClosed' }, {
  group = augroup('auto_balance_windows'),
  callback = function()
    vim.cmd('wincmd =')
  end,
})

-- Close some filetypes with <q>
-- Example: Press 'q' to close help windows, quickfix, etc.
vim.api.nvim_create_autocmd('FileType', {
  group = augroup('close_with_q'),
  pattern = {
    'PlenaryTestPopup',
    'checkhealth',
    'dbout',
    'gitsigns.blame',
    'help',
    'lspinfo',
    'man',
    'neotest-output',
    'neotest-output-panel',
    'neotest-summary',
    'notify',
    'qf',
    'query',
    'spectre_panel',
    'startuptime',
    'tsplayground',
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = event.buf, silent = true })
  end,
})

-- ========================================
-- Filetype Specific Settings
-- ========================================

-- Wrap and check for spell in text filetypes
-- Example: Markdown files have word wrap and spell checking enabled
vim.api.nvim_create_autocmd('FileType', {
  group = augroup('wrap_spell'),
  pattern = { 'text', 'plaintex', 'typst', 'gitcommit', 'markdown' },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
    vim.opt_local.linebreak = true -- Wrap at word boundaries
  end,
})

-- Fix conceallevel for json files
-- Example: JSON files show quotes and formatting characters
vim.api.nvim_create_autocmd({ 'FileType' }, {
  group = augroup('json_conceal'),
  pattern = { 'json', 'jsonc', 'json5' },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

-- Set indentation for specific filetypes
-- Example: Python uses 4 spaces, Go uses tabs
vim.api.nvim_create_autocmd('FileType', {
  group = augroup('filetype_indent'),
  pattern = { 'python', 'rust' },
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = augroup('filetype_indent_tabs'),
  pattern = { 'go', 'makefile' },
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
  end,
})

-- ========================================
-- Performance & Editing
-- ========================================

-- Disable relative numbers in insert mode for better performance
-- Example: Shows absolute numbers when inserting text
vim.api.nvim_create_autocmd('InsertEnter', {
  group = augroup('relative_number_off'),
  callback = function()
    if vim.o.relativenumber then
      vim.o.relativenumber = false
      vim.b.had_relativenumber = true
    end
  end,
})

vim.api.nvim_create_autocmd('InsertLeave', {
  group = augroup('relative_number_on'),
  callback = function()
    if vim.b.had_relativenumber then
      vim.o.relativenumber = true
      vim.b.had_relativenumber = nil
    end
  end,
})

-- Remove trailing whitespace on save
-- Example: Automatically cleans up trailing spaces when you save
vim.api.nvim_create_autocmd('BufWritePre', {
  group = augroup('trim_whitespace'),
  pattern = '*',
  callback = function()
    -- Skip binary files and certain filetypes
    local exclude = { 'diff', 'git', 'markdown' }
    if vim.tbl_contains(exclude, vim.bo.filetype) then
      return
    end
    local save = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

-- Auto-format on save for specific filetypes
-- Example: Formats code when saving if LSP formatter is available
vim.api.nvim_create_autocmd('BufWritePre', {
  group = augroup('lsp_format_on_save'),
  pattern = { '*.lua', '*.ts', '*.tsx', '*.js', '*.jsx', '*.go', '*.rs', '*.py' },
  callback = function()
    -- Only format if LSP client supports it
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    for _, client in ipairs(clients) do
      if client:supports_method('textDocument/formatting') then
        vim.lsp.buf.format({ async = false, timeout_ms = 3000 })
        break
      end
    end
  end,
})

-- Large file optimizations
-- Example: Disable features for files > 1MB for better performance
vim.api.nvim_create_autocmd('BufReadPre', {
  group = augroup('large_file_opts'),
  callback = function(args)
    local file_size = vim.fn.getfsize(args.file)
    if file_size > 1024 * 1024 then -- 1MB
      vim.b.large_file = true
      vim.opt_local.syntax = 'off'
      vim.opt_local.filetype = 'off'
      vim.opt_local.undofile = false
      vim.opt_local.swapfile = false
      vim.opt_local.foldmethod = 'manual'
      vim.opt_local.spell = false
      vim.opt_local.wrap = false
      vim.opt_local.relativenumber = false
      vim.cmd('syntax clear')
      vim.notify('Large file detected, disabled some features for performance', vim.log.levels.INFO)
    end
  end,
})

-- ========================================
-- Terminal Settings
-- ========================================

-- Set specific settings for terminal buffers
-- Example: No numbers, always insert mode in terminal
vim.api.nvim_create_autocmd('TermOpen', {
  group = augroup('terminal_settings'),
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = 'no'
    vim.opt_local.statuscolumn = ''
    vim.opt_local.spell = false
    vim.cmd('startinsert')
  end,
})

-- Auto enter insert mode when focusing terminal
-- Example: Click on terminal window automatically enters insert mode
vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
  group = augroup('terminal_insert'),
  pattern = 'term://*',
  callback = function()
    vim.cmd('startinsert')
  end,
})

-- ========================================
-- Special File Handling
-- ========================================

-- Disable swap file for specific paths
-- Example: No swap files in /tmp or for large log files
vim.api.nvim_create_autocmd('BufReadPre', {
  group = augroup('no_swap_for_paths'),
  pattern = { '/tmp/*', '*.log', '*.tmp', 'COMMIT_EDITMSG', 'MERGE_MSG' },
  callback = function()
    vim.opt_local.swapfile = false
    vim.opt_local.backup = false
    vim.opt_local.undofile = false
  end,
})

-- Read-only files settings
-- Example: Prevent accidental edits to read-only files
vim.api.nvim_create_autocmd('BufRead', {
  group = augroup('readonly_settings'),
  callback = function()
    if vim.bo.readonly then
      vim.opt_local.modifiable = false
      vim.opt_local.spell = false
      vim.opt_local.list = false
    end
  end,
})
