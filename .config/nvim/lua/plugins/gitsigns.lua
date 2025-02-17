return {
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      local opts = {
        signs = {
          add = { text = "+" },
          change = { text = "~" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "│" },
          untracked = { text = "│" },
        },
        on_attach = function(bufnr)
          local gitsigns = require("gitsigns")

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          map("n", "]h", function()
            if vim.wo.diff then
              vim.cmd.normal({ "]c", bang = true })
            else
              gitsigns.nav_hunk("next")
            end
          end, { desc = "Next Hunk" })

          map("n", "[h", function()
            if vim.wo.diff then
              vim.cmd.normal({ "[c", bang = true })
            else
              gitsigns.nav_hunk("prev")
            end
          end, { desc = "Prev Hunk" })
          map("n", "<leader>ghp", gitsigns.preview_hunk, { desc = "Preview Hunk" })
          map("n", "<leader>ghb", function()
            gitsigns.blame_line({ full = true })
          end, { desc = "Blame Line" })
        end,
      }
      require("gitsigns").setup(opts)
    end,
  },
}
