require("oil").setup({
  default_file_explorer = true,
})

vim.keymap.set("n", "<leader>e", "<cmd>Oil<cr>", { desc = "File Explorer(Oil)" })