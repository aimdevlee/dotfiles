return {
  {
    "ibhagwan/fzf-lua",
    lazy = false,
    config = function()
      -- ref. https://github.com/ibhagwan/fzf-lua/blob/b45881a2043d96506ba628f3bc65a4594b179c4e/doc/fzf-lua.txt#L739
      local fzf = require("fzf-lua")
      fzf.setup({
        files = { previewer = true, formatter = "path.filename_first" },
        winopts = {
          row = 0.5,
          height = 0.7,
          backdrop = 100,
          preview = {
            layout = "vertical",
          },
        },
        fzf_opts = {},
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
        buffers = {},
      })
      local keymap = vim.keymap

      -- stylua: ignore start
      -- ref. https://github.com/ibhagwan/fzf-lua?tab=readme-ov-file#commands
      keymap.set("n", "<leader><leader>", function() fzf.resume() end, { desc = "Resume" })
      keymap.set("n", "<leader>ff", function() fzf.files() end, { desc = "Find Files" })
      keymap.set("n", "<leader>fb", function() fzf.buffers() end, { desc = "Find Buffers" })
      keymap.set("n", "<leader>fc", function() fzf.files({ cwd = vim.fn.stdpath("config")}) end, { desc = "Find Config Files" })
      keymap.set("n", "<leader>fr", function() fzf.oldfiles() end, { desc = "Recent" })
      keymap.set("n", "<leader>fg", function() fzf.git_files() end, { desc = "Find Git Files" })
      keymap.set("n", "<leader>ft", function() fzf.treesitter() end, { desc = "Treesitter" })
      keymap.set("n", "<leader>/", function() fzf.lgrep_curbuf() end, { desc = "Live Grep(buffer)" })
      keymap.set("n", "<leader>?", function() fzf.live_grep_glob() end, { desc = "Live Grep" })

      -- lsp
      keymap.set("n", "<leader>la", function() fzf.lsp_code_actions() end, { desc = "Lsp Code Actions" })
      keymap.set("n", "<leader>ld", function() fzf.lsp_definitions() end, { desc = "Lsp Definitions" })
      keymap.set("n", "<leader>lD", function() fzf.lsp_declarations() end, { desc = "Lsp Declarations" })
      keymap.set("n", "<leader>lI", function() fzf.lsp_implementations() end, { desc = "Lsp Implementations" })
      keymap.set("n", "<leader>lr", function() fzf.lsp_references() end, { desc = "Lsp References" })
      keymap.set("n", "<leader>ls", function() fzf.lsp_document_symbols() end, { desc = "Lsp Document Symbols" })
      keymap.set("n", "<leader>lS", function() fzf.lsp_workspace_symbols() end, { desc = "Lsp Workspace Symbols" })
      keymap.set("n", "<leader>lt", function() fzf.lsp_typedefs() end, { desc = "Lsp Type Definitions" })
      -- stylua: ignore end
    end,
  },
}
