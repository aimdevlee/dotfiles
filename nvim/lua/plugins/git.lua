return {
  {
    "tpope/vim-fugitive",
    config = function()
      -- local map = vim.api.nvim_set_keymap
      --
      -- map("n", "<leader>gs", "<cmd>Git<cr>", { desc = "Git: show status" })
      -- map("n", "<leader>gw", "<cmd>Gwrite<cr>", { desc = "Git: add file" })
      -- map("n", "<leader>gc", "<cmd>Git commit<cr>", { desc = "Git: commit changes" })
      -- map("n", "<leader>gpl", "<cmd>Git pull<cr>", { desc = "Git: pull changes" })
      -- map("n", "<leader>gpu", "<cmd>15 split|term git push<cr>", { desc = "Git: push changes" })
      -- map("v", "<leader>gb", ":Git blame<cr>", { desc = "Git: blame selected line" })
    end,
  },
  {
    "sindrets/diffview.nvim",
    lazy = false,
  },
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    config = function()
      vim.api.nvim_set_hl(0, "GitSignsCurrentLineBlame", { fg = "#909aa0" })
      require("gitsigns").setup({
        signs = {
          add = { text = "│" },
          change = { text = "│" },
          delete = { text = "🭻" },
          topdelete = { text = "🭶" },
          changedelete = { text = "~" },
          untracked = { text = "┆" },
        },
        signcolumn = true,
        numhl = true,
        current_line_blame_opts = {
          virt_text_pos = "eol", -- eol | overlay | right_align
          delay = 500,
        },
        current_line_blame_formatter = "  <author>,  <author_time:%R> - <summary>",
        on_attach = function(bufnr)
          local gitsigns = require("gitsigns")

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          map("n", "ghh", "<Cmd>Gitsigns preview_hunk<CR>", { desc = "Preview Hunk" })
          map("n", "ghn", "<Cmd>Gitsigns next_hunk<CR>", { desc = "Next Hunk" })
          map("n", "ghp", "<Cmd>Gitsigns prev_hunk<CR>", { desc = "Prev Hunk" })
          map("n", "ghb", "<Cmd>Gitsigns blame_line<CR>", { desc = "Blame Line" })
          map("n", "ght", "<Cmd>Gitsigns toggle_current_line_blame<CR>", { desc = "Toggle Current Line Blame" })
        end,
      })
    end,
  },
}
