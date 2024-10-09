return {
  {
    "letieu/wezterm-move.nvim",
    keys = {
      {
        "<C-h>",
        function()
          require("wezterm-move").move("h")
        end,
      },
      {
        "<C-j>",
        function()
          require("wezterm-move").move("j")
        end,
      },
      {
        "<C-k>",
        function()
          require("wezterm-move").move("k")
        end,
      },
      {
        "<C-l>",
        function()
          require("wezterm-move").move("l")
        end,
      },
    },
  },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {

      {
        "<leader>tt",
        "<cmd>ToggleTerm<CR>",
        desc = "terminal",
        mode = { "n" },
      },
    },
    opts = {
      direction = "horizontal",
    },
  },
  {
    "willothy/flatten.nvim",
    lazy = false,
    priority = 1001,
    opts = {
      window = {
        open = "alternate",
      },
    },
  },
}
