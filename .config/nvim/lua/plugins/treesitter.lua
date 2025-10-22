return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  config = function()
    require('nvim-treesitter.configs').setup({
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
      sync_install = false,
      auto_install = true,
    })
  end,
}
