return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup({
        preset = "helix",
        icons = {
          mappings = false,
        },
        spec = {
          mode = { "n", "v" },
          -- stylua: ignore start
          {
            "<leader>b", group = "Buffers",
            -- expand = function()
            --   return require("which-key.extras").expand.buf()
            -- end,
          },
          {
            "<leader>w", group = "Windows", proxy = "<c-w>",
            --   expand = function()
            --     return require("which-key.extras").expand.win()
            --   end,
          },
          { "[", group = "Prev" },
          { "]", group = "Next" },
          { "g", group = "Goto" },
          { "sa", group = "surround" },
          { "<leader>a", group = "Ai" },
          { "<leader>c", group = "Code" },
          { "<leader>f", group = "Find/File" },
          { "<leader><tab>", group = "Tabs" },
          { "<leader>g", group = "Git" },
          { "<leader>gh", group = "Hunks" },
          { "<leader>h", group = "Harpoon" },
          { "<leader>t", group = "Toggle" },
          { "<leader>n", group = "Notification" },
          { "<leader>q", group = "Quit/Session" },
          { "<leader>u", group = "UI" },
          { "<leader>x", group = "Diagnostics / Quickfix" },
          { "<leader>y", group = "Yank" },
        },
      })
    end,
  },
}
