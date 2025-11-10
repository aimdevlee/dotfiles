return {
  'stevearc/stickybuf.nvim',
  config = function()
    require('stickybuf').setup({
      get_auto_pin = function(bufnr)
        local buf = vim.api.nvim_get_option_value('filetype', { buf = bufnr })

        if buf == 'dap-view' then
          return nil
        end

        return require('stickybuf').should_auto_pin(bufnr)
      end,
    })
  end,
}
