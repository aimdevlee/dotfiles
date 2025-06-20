-- Hardtime Configuration
return {
  "m4xshen/hardtime.nvim",
  event = { "BufRead" },
  dependencies = { "MunifTanjim/nui.nvim" },
  config = function()
    require("hardtime").setup({
      disabled_filetypes = {
        lazy = false,
        dashboard = false,
        fzf = false,
      },
    })
  end,
}