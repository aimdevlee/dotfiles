return {
  { "Bilal2453/luvit-meta", lazy = true },
  {
    "saghen/blink.cmp",
    lazy = false, -- lazy loading handled internally
    -- optional: provides snippets for the snippet source
    version = "v0.*",
    dependencies = {
      "rafamadriz/friendly-snippets",
      {
        "folke/lazydev.nvim",
        dependencies = { { "Bilal2453/luvit-meta", lazy = true } },
        ft = "lua", -- only load on lua files
        opts = {
          library = {
            -- See the configuration section for more details
            -- Load luvit types when the `vim.uv` word is found
            { path = "luvit-meta/library", words = { "vim%.uv" } },
          },
        },
      },
    },
    opts = {
      sources = {
        -- add lazydev to your completion providers
        default = { "lsp", "path", "snippets", "buffer", "lazydev" },
        providers = {
          -- dont show LuaLS require statements when lazydev has items
          lsp = { fallbacks = { "lazydev" } },
          lazydev = { name = "LazyDev", module = "lazydev.integrations.blink" },
        },
      },
    },
  },
}
