require('lualine').setup({
  options = {
    theme = 'rose-pine',
  },
  sections = {
    lualine_c = {
      {
        function()
          return ' '
        end,
        color = function()
          local status = require('sidekick.status').get()
          if status then
            return status.kind == 'Error' and 'DiagnosticError' or status.busy and 'DiagnosticWarn' or 'Special'
          end
        end,
        cond = function()
          local status = require('sidekick.status')
          return status.get() ~= nil
        end,
      },
    },
  },
})
