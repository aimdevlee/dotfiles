return {
  {
    "nvimdev/dashboard-nvim",
    lazy = false,
    hide = {
      statusline = false,
    },
    config = function()
      local opts = {
        shortcut_type = "number",
        config = {
          week_header = {
            enable = true,
          },
          shortcut = {
            { desc = "󰊳 Update", group = "@property", action = "Lazy update", key = "u" },
            {
              icon = " ",
              -- icon_hl = "@variable",
              desc_hl = "Number",
              desc = "Files",
              -- group = "Label",
              action = "Telescope find_files",
              key = "f",
            },
            {
              icon = "",
              desc = " Restore Session",
              action = 'lua require("persistence").load()',
              key = "s",
            },
          },
          mru = {
            cwd_only = true,
          },
        },
      }

      if vim.o.filetype == "lazy" then
        vim.api.nvim_create_autocmd("WinClosed", {
          pattern = tostring(vim.api.nvim_get_current_win()),
          once = true,
          callback = function()
            vim.schedule(function()
              vim.api.nvim_exec_autocmds("UIEnter", { group = "dashboard" })
            end)
          end,
        })
      end

      vim.opt.foldenable = false

      require("dashboard").setup(opts)
    end,
  },
}
