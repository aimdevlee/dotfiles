return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local use_globalstatus = vim.fn.has("nvim-0.8.0") > 0

      local opts = {
        options = {
          theme = "auto",
          globalstatus = use_globalstatus,
          disabled_filetypes = { "dashboard", "snacks_dashboard" },
          always_divide_middle = true,
          component_separators = "",
          section_separators = { left = "", right = "" },
        },
        sections = {
          lualine_a = { { "mode", separator = { left = "", right = "" }, padding = 1 } },
          lualine_b = { { "branch" } },
          lualine_c = {
            {
              "filename",
              path = 1,
            },
          },
          lualine_x = {
            {
              "diff",
              source = function()
                local gitsigns = vim.b.gitsigns_status_dict
                if gitsigns then
                  return { added = gitsigns.added, modified = gitsigns.changed, removed = gitsigns.removed }
                end
              end,
            },
            { "diagnostics", always_visible = true, symbols = { error = "E", warn = "W", info = "I", hint = "H" } },
            {
              "searchcount",
              maxcount = 999,
              timeout = 500,
            },
          },
          lualine_y = {
            { "progress", separator = " ", padding = { left = 1, right = 0 } },
            { "location", padding = { left = 0, right = 1 } },
          },
          lualine_z = {
            {
              function()
                return " " .. os.date("%R")
              end,
              separator = { left = "", right = "" },
              padding = 1,
            },
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
        extensions = { "neo-tree", "lazy" },
      }

      require("lualine").setup(opts)
    end,
  },
}
