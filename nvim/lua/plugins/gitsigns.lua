-- Gitsigns Git Integration Configuration
return {
  "lewis6991/gitsigns.nvim",
  event = "VeryLazy",
  config = function()
    vim.api.nvim_set_hl(0, "GitSignsCurrentLineBlame", { fg = "#909aa0" })
    vim.api.nvim_set_hl(0, "FloatBorder", { link = "NoiceCmdlinePopupBorder" })
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
      preview_config = {
        border = "rounded",
      },
      current_line_blame_formatter = "  <author>,  <author_time:%R> - <summary>",
      on_attach = function(bufnr)
        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- hunk
        map("n", "<leader>ghh", "<Cmd>Gitsigns preview_hunk<CR>", { desc = "Preview Hunk" })
        map("n", "<leader>ghr", "<Cmd>Gitsigns reset_hunk<CR>", { desc = "Reset Hunk" })
        map("n", "<leader>ghn", "<Cmd>Gitsigns next_hunk<CR>", { desc = "Next Hunk" })
        map("n", "<leader>ghp", "<Cmd>Gitsigns prev_hunk<CR>", { desc = "Prev Hunk" })
        -- blame
        map("n", "<leader>gb", "<Cmd>Gitsigns blame_line<CR>", { desc = "Blame Line" })
        map("n", "<leader>gt", "<Cmd>Gitsigns toggle_current_line_blame<CR>", { desc = "Toggle Current Line Blame" })
      end,
    })
  end,
}