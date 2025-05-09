return {
  { "neovim/nvim-lspconfig" },
  {
    "ggandor/leap.nvim",
    config = function()
      local leap = require("leap")
      leap.set_default_mappings()
      leap.opts.case_sensitive = true
      vim.api.nvim_set_hl(0, "LeapBackdrop", { link = "Comment" })
      vim.keymap.set({ "n", "x", "o" }, "gs", function()
        require("leap.remote").action()
      end)
    end,
  },
  {

    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cF",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = { "n", "v" },
        desc = "Format Injected Langs",
      },
    },
    config = function()
      local opts = {
        notify_on_error = false,
        format_on_save = function(_)
          return {
            timeout_ms = 1000,
          }
        end,
        formatters_by_ft = {
          lua = { "stylua" },
          ruby = { "syntax_tree" },
          javascript = { "prettier" },
          typescript = { "prettier" },
          typescriptreact = { "prettier" },
          toml = { "taplo" },
        },
      }
      require("conform").setup(opts)
    end,
  },
  {
    "kylechui/nvim-surround",
    version = "^3.0.0", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({
        -- Configuration here, or leave empty to use defaults
      })
    end,
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({ fast_wrap = {} })
    end,
  },
  {
    "saghen/blink.cmp",
    dependencies = {
      "fang2hou/blink-copilot",
      { "L3MON4D3/LuaSnip", version = "v2.*", dependencies = { "rafamadriz/friendly-snippets" } },
      {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        event = "InsertEnter",
        opts = {
          suggestion = { enabled = false },
          panel = { enabled = false },
          copilot_model = "gpt-4o-2024-08-06",
        },
      },
    },
    version = "1.*",
    config = function()
      require("blink.cmp").setup({
        sources = {
          default = { "lsp", "snippets", "path", "buffer", "copilot" },
          providers = {
            copilot = {
              name = "copilot",
              module = "blink-copilot",
              score_offset = 100,
              async = true,
              opts = {
                debounce = 1000,
              },
            },
          },
        },
        snippets = { preset = "luasnip" },
        cmdline = { enabled = true },
        completion = {
          list = { selection = { preselect = false, auto_insert = false } },
          menu = {
            auto_show = true,
            draw = {
              align_to = "label",
              treesitter = { "lsp" },
              columns = { { "label", "label_description", gap = 1 }, { "kind_icon", gap = 1 }, { "kind" } },
              padding = 1,
            },
            scrollbar = false,
            winblend = 0, -- 10 is better for nontransparency
            winhighlight = "Normal:None,FloatBorder:NoiceCmdlinePopupBorder",
            border = "rounded",
          },
          ghost_text = { enabled = true },
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 500,
            window = {
              border = "rounded",
              winblend = 0,
              winhighlight = "Normal:None,FloatBorder:NoiceCmdlinePopupBorder,EndOfBuffer:None",
              scrollbar = false,
            },
          },
        },
      })
      vim.api.nvim_set_hl(0, "BlinkCmpDocSeparator", { link = "Special" }) -- as same as signature in noice
    end,
  },
}
