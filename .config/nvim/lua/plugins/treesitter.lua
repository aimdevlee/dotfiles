return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main', -- `master` is locked and only supports Nvim 0.10/0.11
  lazy = false, -- main branch does not support lazy-loading
  build = ':TSUpdate', -- parser versions are pinned to the plugin, so update together
  config = function()
    require('nvim-treesitter').install({
      'bash',
      'csv',
      'diff',
      'git_rebase',
      'gitcommit',
      'go',
      'gomod',
      'javascript',
      'json', -- `jsonc` is mapped to this parser by Nvim
      'lua',
      'make',
      'markdown',
      'markdown_inline',
      'python',
      'query',
      'ruby',
      'rust',
      'toml',
      'tsx',
      'typescript',
      'vim',
      'vimdoc',
      'yaml',
    })

    -- Highlighting is a core feature and is not enabled by the plugin.
    -- Nvim only auto-starts it for lua/markdown/help/query, so start it for
    -- every filetype that has a parser available.
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('nvim_treesitter_start', { clear = true }),
      callback = function(event)
        pcall(vim.treesitter.start, event.buf)
      end,
    })
  end,
}
