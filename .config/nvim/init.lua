-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require('options')
require('keymaps')
require('diagnostics')
require('autocmds')
require('lsp')

---@type LazySpec
--- type can refers because lua_ls workspace.library setting
local plugins = 'plugins'
require('lazy').setup(plugins, {
  checker = { enabled = true },
  change_detection = { enabled = true, notify = false },
  install = { missing = false },
  rocks = {
    enabled = false,
  },
  performance = {
    rtp = {
      ---@type string[]
      disabled_plugins = {
        -- "gzip",
        -- "matchit",
        -- "matchparen",
        'netrwPlugin',
        -- "tarPlugin",
        -- "tohtml",
        'tutor',
        -- "zipPlugin",
      },
    },
  },
})

require('vim._extui').enable({
  enabled = true,
  msg = {
    target = 'msg',
  },
})
