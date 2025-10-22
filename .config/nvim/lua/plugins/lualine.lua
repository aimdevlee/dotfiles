return {
  'nvim-lualine/lualine.nvim',
  enabled = false,
  config = function()
    local lualine = require('lualine')

    local p = require('rose-pine.palette')

    local bg_base = p.surface
    if require('rose-pine.config').options.styles.transparency then
      bg_base = 'NONE'
    end

    local rose_pine = {
      normal = {
        a = { bg = bg_base, fg = p.love, gui = 'bold' },
        b = { bg = bg_base, fg = p.pine },
        c = { bg = bg_base, fg = p.gold },
        z = { bg = bg_base, fg = p.foam },
        y = { bg = bg_base, fg = p.iris },
        x = { bg = bg_base, fg = p.rose },
      },
      insert = {
        a = { bg = bg_base, fg = p.pine, gui = 'bold' },
        b = { bg = bg_base, fg = p.pine },
        c = { bg = bg_base, fg = p.gold },
        z = { bg = bg_base, fg = p.foam },
        y = { bg = bg_base, fg = p.iris },
        x = { bg = bg_base, fg = p.rose },
      },
      visual = {
        a = { bg = bg_base, fg = p.gold, gui = 'bold' },
        b = { bg = bg_base, fg = p.pine },
        c = { bg = bg_base, fg = p.gold },
        z = { bg = bg_base, fg = p.foam },
        y = { bg = bg_base, fg = p.iris },
        x = { bg = bg_base, fg = p.rose },
      },
      replace = {
        a = { bg = bg_base, fg = p.foam, gui = 'bold' },
        b = { bg = bg_base, fg = p.pine },
        c = { bg = bg_base, fg = p.gold },
        z = { bg = bg_base, fg = p.foam },
        y = { bg = bg_base, fg = p.iris },
        x = { bg = bg_base, fg = p.rose },
      },
      command = {
        a = { bg = bg_base, fg = p.iris, gui = 'bold' },
        b = { bg = bg_base, fg = p.pine },
        c = { bg = bg_base, fg = p.gold },
        z = { bg = bg_base, fg = p.foam },
        y = { bg = bg_base, fg = p.iris },
        x = { bg = bg_base, fg = p.rose },
      },
      inactive = {
        a = { bg = bg_base, fg = p.rose, gui = 'bold' },
        b = { bg = bg_base, fg = p.pine },
        c = { bg = bg_base, fg = p.gold },
        z = { bg = bg_base, fg = p.foam },
        y = { bg = bg_base, fg = p.iris },
        x = { bg = bg_base, fg = p.rose },
      },
      terminal = {
        a = { bg = bg_base, fg = p.rose, gui = 'bold' },
        b = { bg = bg_base, fg = p.pine },
        c = { bg = bg_base, fg = p.gold },
        z = { bg = bg_base, fg = p.foam },
        y = { bg = bg_base, fg = p.iris },
        x = { bg = bg_base, fg = p.rose },
      },
    }

    -- Config
    local config = {
      options = {
        disabled_filetypes = {
          statusline = {},
        },
        component_separators = '',
        section_separators = '',
        globalstatus = true,
        theme = rose_pine,
      },
      sections = {
        lualine_a = {
          {
            function()
              if vim.fn.reg_recording() ~= '' then
                local animated = { ' ', '  ' }
                return animated[os.date('%S') % #animated + 1]
              else
                return ' '
              end
            end,
          },
        },
        lualine_b = {
          { 'filename', padding = -1 },
          'branch',
          'diff',
        },
        lualine_c = {},
        lualine_x = { 'diagnostics' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
      },
    }

    lualine.setup(config)
  end,
}
