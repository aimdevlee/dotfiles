-- Which-key Keybinding Helper Configuration
return {
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
        { "<leader>a", group = "Ai" },
        { "<leader>s", group = "Search" },
        { "<leader>c", group = "Code" },
        { "<leader>f", group = "Find/File" },
        { "<leader><tab>", group = "Tabs" },
        { "<leader>g", group = "Git" },
        { "<leader>gh", group = "Hunks" },
        { "<leader>h", group = "Harpoon", expand = function ()
          -- create keymap dynamically to navigate harpoon files
          local harpoon = require('harpoon')
          local list = harpoon:list()
          local keys = {}
          for _, item in ipairs(list.items) do
            local filename = require('plenary.path'):new(item.value):shorten()
            local idx = #keys + 1
            keys[idx] =  {
              ''..idx..'', function ()
                harpoon:list():select(idx)
              end, desc = filename
            }
          end

          return keys
        end},
        { "<leader>t", group = "Toggle" },
        { "<leader>n", group = "Notification" },
        { "<leader>q", group = "Quit/Session" },
        { "<leader>u", group = "UI" },
        { "<leader>x", group = "Diagnostics / Quickfix" },
        { "<leader>y", group = "Yank" },
      },
    })
  end,
}