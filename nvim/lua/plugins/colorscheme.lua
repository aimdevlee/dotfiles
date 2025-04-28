return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        --   dim_inactive = {
        --     enabled = true, -- dims the background color of inactive window
        --     shade = "dark",
        --     percentage = 0.5, -- percentage of the shade to apply to the inactive window
        --   },
        transparent_background = true,
        integrations = {
          blink_cmp = true,
          dashboard = true,
          diffview = true,
          fzf = true,
          gitsigns = true,
          noice = true,
          treesitter = true,
          treesitter_context = true,
          which_key = true,
        },
        custom_highlights = function(colors)
          local u = require("catppuccin.utils.colors")
          return {
            Visual = { bg = u.blend(colors.overlay0, colors.base, 0.75) },
            CursorLine = { bg = u.blend(colors.overlay0, colors.base, 0.45) },
          }
        end,
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
