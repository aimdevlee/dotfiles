return {
  { "nvim-lua/plenary.nvim", lazy = true },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    config = function()
      local harpoon = require("harpoon")
      -- stylua: ignore start
      vim.keymap.set("n", "<leader>ha", function() harpoon:list():add() end, { desc = "Add" })
      vim.keymap.set("n", "<leader>hl", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "List" })
      vim.keymap.set("n", "<leader>h1", function() harpoon:list():select(1) end, { desc = 'Go to first' })
      vim.keymap.set("n", "<leader>h2", function() harpoon:list():select(2) end, { desc = 'Go to second' })
      vim.keymap.set("n", "<leader>h3", function() harpoon:list():select(3) end, { desc = 'Go to third' })
      vim.keymap.set("n", "<leader>h4", function() harpoon:list():select(4) end, { desc = 'Go to fourth' })

      -- Toggle previous & next buffers stored within Harpoon list
      -- vim.keymap.set("n", "<C-S-P>", function() harpoon:list():prev() end)
      -- vim.keymap.set("n", "<C-S-N>", function() harpoon:list():next() end)
      -- stylua: ignore end
    end,
  },
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
      -- move between pane in nvim or tmux or terminal multiplexer
      keymap.set("n", "<C-k>", require("smart-splits").move_cursor_up)
      keymap.set("n", "<C-j>", require("smart-splits").move_cursor_down)
      keymap.set("n", "<C-h>", require("smart-splits").move_cursor_left)
      keymap.set("n", "<C-l>", require("smart-splits").move_cursor_right)
    end,
  },
}
