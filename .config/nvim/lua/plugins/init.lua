return {
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    config = function()
      require('plugins.config.rose-pine')
    end,
  },
  {
    'stevearc/oil.nvim',
    lazy = false,
    config = function()
      require('plugins.config.oil')
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      require('plugins.config.treesitter')
    end,
  },
  {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
    config = function()
      require('plugins.config.conform')
    end,
  },
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('plugins.config.gitsigns')
    end,
  },
  {
    'folke/persistence.nvim',
    event = 'BufReadPre',
    config = function()
      require('plugins.config.persistence')
    end,
  },
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    config = function()
      require('plugins.config.which-key')
    end,
  },
  {
    'mrjones2014/smart-splits.nvim',
    config = function()
      require('plugins.config.smart-splits')
    end,
  },
  {
    'echasnovski/mini.ai',
    event = 'VeryLazy',
    config = function()
      require('plugins.config.mini-ai')
    end,
  },
  {
    'echasnovski/mini.pairs',
    event = 'InsertEnter',
    config = function()
      require('plugins.config.mini-pairs')
    end,
  },
  {
    'echasnovski/mini.surround',
    config = function()
      require('plugins.config.mini-surround')
    end,
  },
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    config = function()
      require('plugins.config.snacks')
    end,
    -- init = function()
    --   vim.api.nvim_create_autocmd('User', {
    --     pattern = 'VeryLazy',
    --     callback = function()
    --       -- Setup some globals for debugging (lazy-loaded)
    --       _G.dd = function(...)
    --         Snacks.debug.inspect(...)
    --       end
    --       _G.bt = function()
    --         Snacks.debug.backtrace()
    --       end
    --
    --       -- Override print to use snacks for `:=` command
    --       if vim.fn.has('nvim-0.11') == 1 then
    --         vim._print = function(_, ...)
    --           dd(...)
    --         end
    --       else
    --         vim.print = _G.dd
    --       end
    --
    --       -- Create some toggle mappings
    --       Snacks.toggle.option('spell', { name = 'Spelling' }):map('<leader>us')
    --       Snacks.toggle.option('wrap', { name = 'Wrap' }):map('<leader>uw')
    --       Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):map('<leader>uL')
    --       Snacks.toggle.diagnostics():map('<leader>ud')
    --       Snacks.toggle.line_number():map('<leader>ul')
    --       Snacks.toggle
    --         .option('conceallevel', { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
    --         :map('<leader>uc')
    --       Snacks.toggle.treesitter():map('<leader>uT')
    --       Snacks.toggle.option('background', { off = 'light', on = 'dark', name = 'Dark Background' }):map('<leader>ub')
    --       Snacks.toggle.inlay_hints():map('<leader>uh')
    --       Snacks.toggle.indent():map('<leader>ug')
    --       Snacks.toggle.dim():map('<leader>uD')
    --     end,
    --   })
    -- end,
  },
  {
    'stevearc/stickybuf.nvim',
    config = function()
      require('plugins.config.stickybuf')
    end,
  },
  {
    'nvim-lualine/lualine.nvim',
    config = function()
      require('plugins.config.lualine')
    end,
  },
  {
    'nvim-tree/nvim-web-devicons',
  },
  {
    'neovim/nvim-lspconfig',
  },
  {
    'saghen/blink.cmp',
    dependencies = { 'rafamadriz/friendly-snippets' },
    version = '1.*',
    opts = {
      keymap = { preset = 'default' },

      appearance = {
        nerd_font_variant = 'mono',
      },

      completion = { documentation = { auto_show = false } },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },

      fuzzy = { implementation = 'prefer_rust_with_warning' },
    },
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
  },
  {
    'folke/sidekick.nvim',
    opts = {
      -- add any options here
      cli = {
        mux = {
          backend = 'tmux',
          enabled = true,
        },
      },
    },
    keys = {
      {
        '<tab>',
        function()
          -- if there is a next edit, jump to it, otherwise apply it if any
          if not require('sidekick').nes_jump_or_apply() then
            return '<Tab>' -- fallback to normal tab
          end
        end,
        expr = true,
        desc = 'Goto/Apply Next Edit Suggestion',
      },
      {
        '<c-.>',
        function()
          require('sidekick.cli').toggle()
        end,
        desc = 'Sidekick Toggle',
        mode = { 'n', 't', 'i', 'x' },
      },
      {
        '<leader>aa',
        function()
          require('sidekick.cli').toggle()
        end,
        desc = 'Sidekick Toggle CLI',
      },
      {
        '<leader>as',
        function()
          require('sidekick.cli').select()
        end,
        -- Or to select only installed tools:
        -- require("sidekick.cli").select({ filter = { installed = true } })
        desc = 'Select CLI',
      },
      {
        '<leader>ad',
        function()
          require('sidekick.cli').close()
        end,
        desc = 'Detach a CLI Session',
      },
      {
        '<leader>at',
        function()
          require('sidekick.cli').send({ msg = '{this}' })
        end,
        mode = { 'x', 'n' },
        desc = 'Send This',
      },
      {
        '<leader>af',
        function()
          require('sidekick.cli').send({ msg = '{file}' })
        end,
        desc = 'Send File',
      },
      {
        '<leader>av',
        function()
          require('sidekick.cli').send({ msg = '{selection}' })
        end,
        mode = { 'x' },
        desc = 'Send Visual Selection',
      },
      {
        '<leader>ap',
        function()
          require('sidekick.cli').prompt()
        end,
        mode = { 'n', 'x' },
        desc = 'Sidekick Select Prompt',
      },
      -- Example of a keybinding to open Claude directly
      {
        '<leader>ac',
        function()
          require('sidekick.cli').toggle({ name = 'claude', focus = true })
        end,
        desc = 'Sidekick Toggle Claude',
      },
    },
  },
}
