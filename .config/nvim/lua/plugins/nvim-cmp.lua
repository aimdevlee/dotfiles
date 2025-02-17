return {
  -- {
  --   "hrsh7th/nvim-cmp",
  --   event = "InsertEnter",
  --   dependencies = {
  --     {
  --       "garymjr/nvim-snippets",
  --       opts = {
  --         friendly_snippets = true,
  --       },
  --       dependencies = { "rafamadriz/friendly-snippets" },
  --     },
  --     "hrsh7th/cmp-nvim-lsp",
  --     "hrsh7th/cmp-path",
  --     "hrsh7th/cmp-buffer",
  --   },
  --   keys = {
  --     {
  --       "<Tab>",
  --       function()
  --         return vim.snippet.active({ direction = 1 }) and "<cmd>lua vim.snippet.jump(1)<cr>" or "<Tab>"
  --       end,
  --       expr = true,
  --       silent = true,
  --       mode = { "i", "s" },
  --     },
  --     {
  --       "<S-Tab>",
  --       function()
  --         return vim.snippet.active({ direction = -1 }) and "<cmd>lua vim.snippet.jump(-1)<cr>" or "<S-Tab>"
  --       end,
  --       expr = true,
  --       silent = true,
  --       mode = { "i", "s" },
  --     },
  --   },
  --   config = function()
  --     local cmp = require("cmp")
  --     local auto_select = false
  --     local opts = {
  --       snippet = {
  --         expand = function(args)
  --           vim.snippet.expand(args.body)
  --         end,
  --       },
  --       completion = {
  --         completeopt = "menu,menuone,noinsert" .. (auto_select and "" or ",noselect"),
  --       },
  --       preselect = auto_select and cmp.PreselectMode.Item or cmp.PreselectMode.None,
  --       mapping = cmp.mapping.preset.insert({
  --         ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
  --         ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
  --         ["<C-b>"] = cmp.mapping.scroll_docs(-4),
  --         ["<C-f>"] = cmp.mapping.scroll_docs(4),
  --         ["<C-Space>"] = cmp.mapping.complete(),
  --         ["<C-y>"] = cmp.mapping.confirm({ select = true }),
  --         ["<C-e>"] = cmp.mapping.abort(),
  --       }),
  --       sources = cmp.config.sources({
  --         {
  --           name = "lazydev",
  --           group_index = 0,
  --         },
  --         { name = "nvim_lsp" },
  --         { name = "path" },
  --         { name = "buffer" },
  --         { name = "snippets" },
  --         { name = "copilot", group_index = 1, priority = 100 },
  --       }),
  --       -- formatting = {
  --       --   format = require("lspkind").cmp_format({
  --       --     mode = "symbol_text",
  --       --     maxwidth = 50,
  --       --     ellipsis_char = "...",
  --       --     show_labelDetails = false,
  --       --     before = function(entry, vim_item)
  --       --       return vim_item
  --       --     end,
  --       --   }),
  --       -- },
  --     }
  --
  --     cmp.setup(opts)
  --     cmp.setup.filetype({ "mysql" }, { sources = { { name = "vim-dadbod-completion" }, { name = "buffer" } } })
  --   end,
  -- },
}
