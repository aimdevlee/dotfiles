return {
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    config = function()
      local logo = [[
-█████╗-██╗███╗---███╗██████╗-███████╗██╗---██╗██╗-----███████╗███████╗
██╔══██╗██║████╗-████║██╔══██╗██╔════╝██║---██║██║-----██╔════╝██╔════╝
███████║██║██╔████╔██║██║--██║█████╗--██║---██║██║-----█████╗--█████╗--
██╔══██║██║██║╚██╔╝██║██║--██║██╔══╝--╚██╗-██╔╝██║-----██╔══╝--██╔══╝--
██║--██║██║██║-╚═╝-██║██████╔╝███████╗-╚████╔╝-███████╗███████╗███████╗
╚═╝--╚═╝╚═╝╚═╝-----╚═╝╚═════╝-╚══════╝--╚═══╝--╚══════╝╚══════╝╚══════╝
      ]]
      logo = string.rep("\n", 8) .. logo .. "\n\n"
      require("dashboard").setup({
        theme = "doom",
        config = {
          header = vim.split(logo, "\n"),
          center = {
            -- stylua: ignore start
            { icon = "", desc = "New File", key = "n", key_format = "[%s]", action = 'enew' },
            { icon = "", desc = "Browse", key = "b", key_format = "[%s]", action = 'Oil' },
            { icon = "", desc = "Recents", key = "r", key_format = "[%s]", action = function() require("fzf-lua").oldfiles() end },
            { icon = "", desc = "Find Files", key = "f", key_format = "[%s]", action = function() require("fzf-lua").files() end },
            { icon = "", desc = "Live Grep in " .. vim.uv.cwd(), key = "g", key_format = "[%s]", action = function() require("fzf-lua").live_grep() end },
            { icon = "", desc = "Find Config Files", key = "c", key_format = "[%s]", action = function() require("fzf-lua").files({ cwd = vim.fn.stdpath("config") }) end },
            { icon = "", desc = "Restore Last Session", key = "s", key_format = "[%s]", action = function() require("persistence").load({ last = true }) end },
            { icon = "", desc = "Lazy", key = "l", key_format = "[%s]", action = 'Lazy' },
            -- stylua: ignore end
          },
          vertical_center = true,
        },
      })
    end,
  },
}
