-- Blink.cmp Completion Configuration
return {
  "saghen/blink.cmp",
  dependencies = {
    "fang2hou/blink-copilot",
    { "L3MON4D3/LuaSnip", version = "v2.*", dependencies = { "rafamadriz/friendly-snippets" } },
  },
  version = "1.*",
  config = function()
    require("blink.cmp").setup({
      sources = {
        default = { "lsp", "snippets", "path", "buffer" },
        per_filetype = {
          codecompanion = { "codecompanion" },
        },
      },
      snippets = { preset = "luasnip" },
      cmdline = { enabled = true },
      completion = {
        list = { selection = { preselect = false, auto_insert = false } },
        menu = {
          auto_show = true,
          draw = {
            align_to = "label",
            treesitter = { "lsp" },
            columns = { { "label", "label_description", gap = 1 }, { "kind_icon", gap = 1 }, { "kind" } },
            padding = 1,
          },
          scrollbar = false,
          winblend = 0, -- 10 is better for nontransparency
          winhighlight = "Normal:None,FloatBorder:NoiceCmdlinePopupBorder",
          border = "rounded",
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 500,
          window = {
            border = "rounded",
            winblend = 0,
            winhighlight = "Normal:None,FloatBorder:NoiceCmdlinePopupBorder,EndOfBuffer:None",
            scrollbar = false,
          },
        },
      },
    })
    vim.api.nvim_set_hl(0, "BlinkCmpDocSeparator", { link = "Special" }) -- as same as signature in noice
  end,
}