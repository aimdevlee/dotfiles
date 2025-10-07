require("which-key").setup({
  icons = {
    mappings = false,
  },
  spec = {
    { "<leader>c", group = "code" },
    { "<leader>f", group = "file/find" },
    { "<leader>g", group = "git" },
    { "<leader>h", group = "git hunk" },
    { "<leader>l", group = "lsp" },
    { "<leader>s", group = "search" },
    { "<leader>sn", group = "noice" },
    { "<leader>u", group = "ui" },
    { "<leader>x", group = "diagnostics/quickfix" },
    { "[", group = "prev" },
    { "]", group = "next" },
    { "g", group = "goto" },
    { "gs", group = "surround" },
  },
})