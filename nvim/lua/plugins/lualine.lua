-- Lualine Statusline Configuration
return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  config = function()
    local use_globalstatus = vim.fn.has("nvim-0.8.0") > 0
    local color = { bg = "none", fg = "#cdd6f4" }
    local opts = {
      options = {
        theme = "catppuccin",
        globalstatus = use_globalstatus,
        disabled_filetypes = {
          "snacks_dashboard",
          "dashboard",
          "gitsigns-blame",
          "noice",
          "fugitive",
          "oil",
          "qf",
        },
        always_divide_middle = true,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = {
          {
            "mode",
            padding = 1,
            cond = function()
              return vim.fn.reg_recording() == ""
            end,
          },
          {
            "macro",
            fmt = function()
              local reg = vim.fn.reg_recording()
              if reg ~= "" then
                return " Recording @" .. reg
              end
              return nil
            end,
            color = { bg = "#cba6f7", gui = "italic,bold" },
            draw_empty = false,
          },
        },
        lualine_b = {
          { "branch", color = color },
          { "filename", path = 1, color = color },
          { "diagnostics", color = color },
        },
        lualine_c = {},
        lualine_x = {
          {
            "diff",
            source = function()
              local gitsigns = vim.b.gitsigns_status_dict
              if gitsigns then
                return { added = gitsigns.added, modified = gitsigns.changed, removed = gitsigns.removed }
              end
            end,
            color = color,
          },
          {
            "searchcount",
            maxcount = 999,
            timeout = 500,
            color = color,
          },
        },
        lualine_y = {},
        lualine_z = {
          {
            "progress",
            padding = { left = 1, right = 1 },
            color = color,
          },
          { "location", padding = { left = 1 }, color = color },
        },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },
      extensions = { "lazy", "oil", "fzf", "fugitive", "man" },
    }

    require("lualine").setup(opts)
  end,
}