return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local opts = {
        spec = {
          mode = { "n", "v" },
          {
            "<leader>b",
            group = "buffer",
            -- expand = function()
            --   return require("which-key.extras").expand.buf()
            -- end,
          },
          {
            "<leader>w",
            group = "windows",
            proxy = "<c-w>",
            --   expand = function()
            --     return require("which-key.extras").expand.win()
            --   end,
          },
          { "[", group = "prev" },
          { "]", group = "next" },
          { "g", group = "goto" },
          -- { "sa", group = "surround" },
          { "z", group = "fold" },
          { "<leader>a", group = "+ai" },
          {
            "<leader>e",
            group = "explorer",
            icon = { cat = "filetype", name = "neo-tree" },
          },
          { "<leader>c", group = "code" },
          { "<leader>f", group = "find/file" },
          { "<leader>s", group = "search" },
          { "<leader><tab>", group = "tabs" },
          { "<leader>g", group = "git" },
          { "<leader>gh", group = "hunks" },
          { "<leader>t", group = "toggle" },
          { "<leader>q", group = "quit/session" },
          { "<leader>u", group = "ui" },
          { "<leader>x", group = "diagnostics/quickfix" },
          { "<BS>", desc = "Decrement Selection", mode = "x" },
          { "<c-space>", desc = "Increment Selection", mode = { "x", "n" } },
        },
      }
      require("which-key").setup(opts)
    end,
  },
}
