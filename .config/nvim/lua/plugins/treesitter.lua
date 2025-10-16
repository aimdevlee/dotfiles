require('nvim-treesitter.configs').setup({
  -- Add languages you use
  ensure_installed = {
    'lua',
    'vim',
    'vimdoc',
    'query',
    'markdown',
    'markdown_inline',
    'bash',
    'javascript',
    'typescript',
    'regex',
    'tsx',
    'json',
    'yaml',
    'toml',
    'html',
    'css',
    'python',
    'go',
    'rust',
    'ruby',
  },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  -- Disabled for better startup performance - install parsers manually if needed
  auto_install = false,

  highlight = {
    enable = true,
  },
})
