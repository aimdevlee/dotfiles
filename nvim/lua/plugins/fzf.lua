return {
  {
    "ibhagwan/fzf-lua",
    lazy = false,
    config = function()
      require("fzf-lua").setup({
        files = { previewer = false },
        winopts = {
          row = 0.5,
          height = 0.7,
          backdrop = 100,
          preview = {
            layout = "vertical",
          },
        },
        keymap = {
          builtin = {
            ["<M-Esc>"] = "hide",
            ["<F1>"] = "toggle-help",
            ["<F2>"] = "toggle-fullscreen",
            ["<F3>"] = "toggle-preview-wrap",
            ["<F4>"] = "toggle-preview",
            ["<F5>"] = "toggle-preview-ccw",
            ["<F6>"] = "toggle-preview-cw",
            ["<F7>"] = "toggle-preview-ts-ctx",
            ["<F8>"] = "preview-ts-ctx-dec",
            ["<F9>"] = "preview-ts-ctx-inc",
            ["<M-S-r>"] = "preview-reset",
            ["<M-S-n>"] = "preview-page-down",
            ["<M-S-p>"] = "preview-page-up",
            ["<M-n>"] = "preview-down",
            ["<M-p>"] = "preview-up",
          },
        },
      })
      local FzfLua = require("fzf-lua")
      local keymap = vim.keymap

      -- stylua: ignore start
      -- ref. https://github.com/ibhagwan/fzf-lua?tab=readme-ov-file#commands
      keymap.set("n", "<leader><leader>", function() FzfLua.resume() end, { desc = "Resume" })
      keymap.set("n", "<leader>ff", function() FzfLua.files() end, { desc = "Find Files" })
      keymap.set("n", "<leader>fb", function() FzfLua.buffers() end, { desc = "Find Buffers" })
      keymap.set("n", "<leader>fc", function() FzfLua.files({ cwd = vim.fn.stdpath("config")}) end, { desc = "Find Config Files" })
      keymap.set("n", "<leader>fr", function() FzfLua.oldfiles() end, { desc = "Recent" })
      keymap.set("n", "<leader>fg", function() FzfLua.git_files() end, { desc = "Find Git Files" })
      keymap.set("n", "<leader>ft", function() FzfLua.treesitter() end, { desc = "Treesitter" })
      keymap.set("n", "<leader>/", function() FzfLua.lgrep_curbuf() end, { desc = "Live Grep(buffer)" })
      keymap.set("n", "<leader>?", function() FzfLua.live_grep_glob() end, { desc = "Live Grep" })

      -- lsp
      keymap.set("n", "ga", function() FzfLua.lsp_code_actions() end, { desc = "Lsp Code Actions" })
      keymap.set("n", "gd", function() FzfLua.lsp_definitions() end, { desc = "Lsp Definitions" })
      keymap.set("n", "gD", function() FzfLua.lsp_declarations() end, { desc = "Lsp Declarations" })
      keymap.set("n", "gI", function() FzfLua.lsp_implementations() end, { desc = "Lsp Implementations" })
      keymap.set("n", "gr", function() FzfLua.lsp_references() end, { desc = "Lsp References" })
      keymap.set("n", "gs", function() FzfLua.lsp_document_symbols() end, { desc = "Lsp Document Symbols" })
      keymap.set("n", "gS", function() FzfLua.lsp_workspace_symbols() end, { desc = "Lsp Workspace Symbols" })
      keymap.set("n", "gt", function() FzfLua.lsp_typedefs() end, { desc = "Lsp Type Definitions" })
      -- stylua: ignore end
    end,
  },
}
