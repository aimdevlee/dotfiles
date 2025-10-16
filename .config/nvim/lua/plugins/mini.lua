require('mini.ai').setup({ n_lines = 500 })
require('mini.pairs').setup()
require('mini.surround').setup()
local clue = require('mini.clue')
local extra = require('mini.extra')
local files = require('mini.files')
local pick = require('mini.pick')
local sessions = require('mini.sessions')
local starter = require('mini.starter')
files.setup()
extra.setup()
pick.setup()
sessions.setup()
starter.setup({
  evaluate_single = true,
  items = {
    starter.sections.sessions(),
    { name = 'New', action = 'enew', section = 'Menu' },
    { name = 'Explorer', action = 'lua MiniFiles.open()', section = 'Menu' },
    { name = 'Files', action = 'Pick files', section = 'Menu' },
    { name = 'Configs', action = 'Pick files', section = 'Menu' },
    { name = 'Grep live', action = 'Pick grep_live', section = 'Menu' },
    { name = 'Quit Neovim', action = 'qall', section = 'Menu' },
  },
  -- content_hooks = {
  --   starter.gen_hook.adding_bullet(),
  -- },
  header = [[]],
  footer = [[]],
  silent = true,
})

clue.setup({
  window = {
    config = { anchor = 'SW', row = 'auto', col = 'auto', width = 'auto', height = 10 },
    delay = 200,
  },
  triggers = {
    -- Leader triggers
    { mode = 'n', keys = '<Leader>' },
    { mode = 'x', keys = '<Leader>' },

    -- Built-in completion
    { mode = 'i', keys = '<C-x>' },

    -- `g` key
    { mode = 'n', keys = 'g' },
    { mode = 'x', keys = 'g' },

    -- Marks
    { mode = 'n', keys = "'" },
    { mode = 'n', keys = '`' },
    { mode = 'x', keys = "'" },
    { mode = 'x', keys = '`' },

    -- Registers
    { mode = 'n', keys = '"' },
    { mode = 'x', keys = '"' },
    { mode = 'i', keys = '<C-r>' },
    { mode = 'c', keys = '<C-r>' },

    -- Window commands
    { mode = 'n', keys = '<C-w>' },

    -- `z` key
    { mode = 'n', keys = 'z' },
    { mode = 'x', keys = 'z' },

    -- Brackets
    { mode = 'n', keys = '[' },
    { mode = 'n', keys = ']' },
  },

  clues = {
    -- Enhance this by adding descriptions for <Leader> mapping groups
    clue.gen_clues.builtin_completion(),
    clue.gen_clues.g(),
    clue.gen_clues.marks(),
    clue.gen_clues.registers(),
    clue.gen_clues.windows(),
    clue.gen_clues.z(),
    clue.gen_clues.square_brackets(),
    { mode = 'n', keys = '<Leader>s', desc = '+Search' },
    { mode = 'n', keys = '<Leader>b', desc = '+Buffers' },
    { mode = 'n', keys = '<Leader>q', desc = '+Quit' },
    { mode = 'n', keys = '<Leader><tab>', desc = '+Tab' },
    { mode = 'n', keys = '<Leader>y', desc = '+Yank' },
    { mode = 'n', keys = '<Leader>t', desc = '+Toggle' },
    { mode = 'n', keys = '<Leader>g', desc = '+Git' },
    { mode = 'n', keys = '<Leader>f', desc = '+Find' },
  },
})
-- keymap --
vim.keymap.set('n', '<leader>e', ':lua MiniFiles.open()', { desc = 'Exploere' })
vim.keymap.set('n', '<leader>qq', function()
  local session_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
  sessions.write(session_name)
  vim.cmd('qa')
end, { desc = 'Quit with session' })
vim.keymap.set('n', '<leader>ff', function()
  pick.builtin.files()
end, { desc = 'Files', silent = true })
vim.keymap.set('n', '<leader>fb', function()
  pick.builtin.buffers()
end, { desc = 'Buffers', silent = true })
vim.keymap.set('n', '<leader>sg', function()
  pick.builtin.grep_live()
end, { desc = 'Live grep', silent = true })
vim.keymap.set('n', '<leader><leader>', function()
  pick.builtin.resume()
end, { desc = 'Resume', silent = true })
vim.keymap.set('n', '<leader>sh', function()
  pick.builtin.help()
end, { desc = 'Help', silent = true })
vim.keymap.set('n', '<leader>fc', function()
  pick.builtin.files({}, { source = { cwd = vim.fn.stdpath('config') } })
end, { desc = 'Configs', silent = true })
vim.keymap.set('n', '<leader>sr', function()
  extra.pickers.oldfiles()
end, { desc = 'Old files', silent = true })
vim.keymap.set('n', '<leader>gf', function()
  extra.pickers.git_files()
end, { desc = 'Files', silent = true })
vim.keymap.set('n', '<leader>sc', function()
  extra.pickers.commands()
end, { desc = 'Commands', silent = true })
vim.keymap.set('n', '<leader>sH', function()
  extra.pickers.hl_groups()
end, { desc = 'Highlight groups', silent = true })
vim.keymap.set('n', 'grr', function()
  extra.pickers.lsp({ scope = 'references' })
end, { desc = 'References', silent = true })
vim.keymap.set('n', 'gri', function()
  extra.pickers.lsp({ scope = 'implementation' })
end, { desc = 'Implementation', silent = true })
vim.keymap.set('n', 'grt', function()
  extra.pickers.lsp({ scope = 'type_definition' })
end, { desc = 'Type definition', silent = true })
vim.keymap.set('n', 'grs', function()
  extra.pickers.lsp({ scope = 'document_symbol' })
end, { desc = 'Document symbol', silent = true })
vim.keymap.set('n', 'grS', function()
  extra.pickers.lsp({ scope = 'workspace_symbol' })
end, { desc = 'Workspace symbol', silent = true })
vim.keymap.set('n', 'grd', function()
  extra.pickers.lsp({ scope = 'definition' })
end, { desc = 'Definition', silent = true })
