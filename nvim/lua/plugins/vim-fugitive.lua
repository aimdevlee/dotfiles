-- Vim Fugitive Git Integration Configuration
return {
  "tpope/vim-fugitive",
  config = function()
    -- Commented out keymaps - uncomment and customize as needed
    -- local map = vim.api.nvim_set_keymap
    --
    -- map("n", "<leader>gs", "<cmd>Git<cr>", { desc = "Git: show status" })
    -- map("n", "<leader>gw", "<cmd>Gwrite<cr>", { desc = "Git: add file" })
    -- map("n", "<leader>gc", "<cmd>Git commit<cr>", { desc = "Git: commit changes" })
    -- map("n", "<leader>gpl", "<cmd>Git pull<cr>", { desc = "Git: pull changes" })
    -- map("n", "<leader>gpu", "<cmd>15 split|term git push<cr>", { desc = "Git: push changes" })
    -- map("v", "<leader>gb", ":Git blame<cr>", { desc = "Git: blame selected line" })
  end,
}