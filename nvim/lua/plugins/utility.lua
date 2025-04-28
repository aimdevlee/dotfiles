return {
  { "nvim-lua/plenary.nvim", lazy = true },
  {
    "stevearc/oil.nvim",
    lazy = false,
    config = function()
      require("oil").setup({
        default_file_explorer = true,
      })

      vim.keymap.set("n", "<leader>e", "<cmd>Oil<cr>", { desc = "File Explorer(Oil)" })
    end,
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre", -- this will only start session saving when an actual file was opened
    opts = {
      -- add any custom options here
    },
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      {
        "rcarriga/nvim-notify",
        config = function()
          require("notify").setup({ background_colour = "#000000" })
        end,
      },
    },
    config = function()
      require("noice").setup({
        presets = {
          command_palette = true,
        },
        routes = {
          {
            filter = {
              event = "notify",
              find = "No information available",
            },
            opts = { skip = true },
          },
        },
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
          },
          hover = {
            enabled = true,
            silent = true,
          },
          signature = {
            enabled = true,
            auto_open = {
              enabled = false,
              trigger = true, -- Automatically show signature help when typing a trigger character from the LSP
              luasnip = true, -- Will open signature help when jumping to Luasnip insert nodes
              throttle = 50, -- Debounce lsp signature help request by 50ms
            },
            view = nil, -- when nil, use defaults from documentation
            opts = {}, -- merged with defaults from documentation
          },
        },
        views = {
          -- as same as blink completion menu style
          hover = {
            border = {
              style = "rounded",
              padding = { 0, 1 },
            },
            position = { row = 2, col = 0 },
            win_options = {
              winblend = 10,
              winhighlight = { Normal = "None", FloatBorder = "NoiceCmdlinePopupBorder" },
            },
          },
        },
      })
    end,
  },
  {
    "mrjones2014/smart-splits.nvim",
    config = function()
      require("smart-splits").setup({ at_edge = "stop" })
      local keymap = vim.keymap
      -- resize
      keymap.set("n", "<C-w>/", require("smart-splits").start_resize_mode)

      -- move between pane in nvim or tmux or terminal multiplexer
      keymap.set("n", "<C-k>", require("smart-splits").move_cursor_up)
      keymap.set("n", "<C-j>", require("smart-splits").move_cursor_down)
      keymap.set("n", "<C-h>", require("smart-splits").move_cursor_left)
      keymap.set("n", "<C-l>", require("smart-splits").move_cursor_right)
    end,
  },
}
