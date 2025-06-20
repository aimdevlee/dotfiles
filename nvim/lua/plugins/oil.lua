-- Oil File Explorer Configuration
return {
  "stevearc/oil.nvim",
  lazy = false,
  config = function()
    require("oil").setup({
      default_file_explorer = true,
    })

    vim.keymap.set("n", "<leader>e", "<cmd>Oil<cr>", { desc = "File Explorer(Oil)" })
  end,
}