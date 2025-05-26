return {
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },
  {
    "b0o/incline.nvim",
    event = "BufRead",
    config = function()
      require("incline").setup({
        window = { options = { winblend = 0 } },
        render = function(props)
          local devicons = require("nvim-web-devicons")
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
          if filename == "" then
            filename = "[No Name]"
          end
          local ft_icon, ft_color = devicons.get_icon_color(filename)

          local function get_diagnostic_label()
            local icons = { error = "", warn = "", info = "", hint = "" }
            local label = {}

            for severity, icon in pairs(icons) do
              local n = #vim.diagnostic.get(props.buf, { severity = vim.diagnostic.severity[string.upper(severity)] })
              if n > 0 then
                table.insert(label, { icon .. n .. " ", group = "DiagnosticSign" .. severity })
              end
            end
            if #label > 0 then
              table.insert(label, { "┊" })
            end
            return label
          end

          return {
            { get_diagnostic_label() },
            ft_icon and { " " .. ft_icon .. " ", guifg = ft_color } or "",
            { " " .. filename .. " ", gui = vim.bo[props.buf].modified and "bold,italic" or "bold" },
          }
        end,
      })
    end,
  },
  {
    "sphamba/smear-cursor.nvim",
    enabled = false,
    config = function()
      require("smear_cursor").setup({
        min_horizontal_distance_smear = 3,
        min_vertical_distance_smear = 3,
        stiffness = 0.6,
        trailing_stiffness = 0.4,
        trailing_exponent = 1.5,
        slowdown_exponent = -0.1,
        distance_stop_animating = 0.1,
      })
    end,
  },
  {
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
                  return " Recording @" .. reg
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
  },
}
