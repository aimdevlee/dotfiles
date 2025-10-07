require("nvim-treesitter.configs").setup({
  -- Add languages you use
  ensure_installed = {
    "lua",
    "vim",
    "vimdoc",
    "query",
    "markdown",
    "markdown_inline",
    "bash",
    "nix",
    "javascript",
    "typescript",
    "regex",
    "tsx",
    "json",
    "yaml",
    "toml",
    "html",
    "css",
    "python",
    "go",
    "rust",
  },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  auto_install = true,

  highlight = {
    enable = true,
    -- Disable for large files
    disable = function(lang, buf)
      local max_filesize = 100 * 1024 -- 100 KB
      local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
      if ok and stats and stats.size > max_filesize then
        return true
      end
    end,
  },

  -- Indentation based on treesitter (experimental)
  indent = {
    enable = true,
  },

  -- Incremental selection
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<C-space>",
      node_incremental = "<C-space>",
      scope_incremental = false,
      node_decremental = "<bs>",
    },
  },
})

