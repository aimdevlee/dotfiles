-- Incline Floating Statuslines Configuration
return {
  "b0o/incline.nvim",
  enabled = false,
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
          local icons = { error = "", warn = "", info = "", hint = "" }
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
}