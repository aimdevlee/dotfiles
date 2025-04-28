if vim.g.vscode == 1 then
else
  require("config.options")
  require("config.keymaps")
  require("config.autocmds")
  require("config.lazy")
  require("config.lsp")
end
