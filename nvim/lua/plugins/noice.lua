-- Noice UI Enhancement Configuration
return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    {
      "rcarriga/nvim-notify",
      config = function()
        require("notify").setup({ background_colour = "#000000" })
      end,
    },
  },
  config = function()
    require("noice").setup({
      presets = {
        command_palette = true,
      },
      routes = {
        {
          filter = {
            event = "notify",
            find = "No information available",
          },
          opts = { skip = true },
        },
      },
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
        hover = {
          enabled = true,
          silent = true,
        },
        signature = {
          enabled = true,
          auto_open = {
            enabled = false,
            trigger = true,
            luasnip = true,
            throttle = 50,
          },
          view = nil,
          opts = {},
        },
      },
      views = {
        hover = {
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
          position = { row = 2, col = 0 },
          win_options = {
            winblend = 10,
            winhighlight = { Normal = "None", FloatBorder = "NoiceCmdlinePopupBorder" },
          },
        },
      },
    })
  end,
}