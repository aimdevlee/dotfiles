return {
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPost", "BufNewFile", "BufWritePre" },
    main = "ibl",
    config = function()
      local exclude_ft = {
        "help",
        "dashboard",
        "neo-tree",
        "lazy",
        "mason",
        "notify",
        "git",
        "markdown",
        "snacks_dashboard",
      }

      local opts = {
        indent = { char = "│", smart_indent_cap = true },
        scope = {
          enabled = false,
        },
        exclude = {
          filetypes = exclude_ft,
        },
      }
      require("ibl").setup(opts)

      local gid = vim.api.nvim_create_augroup("indent_blankline", { clear = true })

      vim.api.nvim_create_autocmd("InsertEnter", {
        pattern = "*",
        group = gid,
        command = "IBLDisable",
      })

      vim.api.nvim_create_autocmd("InsertLeave", {
        pattern = "*",
        group = gid,
        callback = function()
          if not vim.tbl_contains(exclude_ft, vim.bo.filetype) then
            vim.cmd([[IBLEnable]])
          end
        end,
      })
    end,
  },
}
