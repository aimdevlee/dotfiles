return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    lazy = true,
    keys = {
      { "<leader>os", "<cmd>Obsidian search<cr>", desc = "Search Note" },
      { "<leader>of", "<cmd>Obsidian quick_switch<cr>", desc = "Find Note" },
      { "<leader>on", "<cmd>Obsidian new<cr>", desc = "Create New Note" },
      { "<leader>ot", "<cmd>Obsidian today<cr>", desc = "Create or Open Today Note" },
    },
    ft = "markdown",
    config = function()
      require("obsidian").setup({
        workspaces = {
          {
            name = "work",
            path = "~/vaults/work",
          },
        },
        completion = {
          nvim_cmp = false,
          blink = true,
        },
        picker = {
          name = "snacks.pick",
        },
      })
    end,
  },
}
