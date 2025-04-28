local function augroup(name)
  return vim.api.nvim_create_augroup("neovim_" .. name, { clear = true })
end

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- disable auto comment when line break by <cr> <o> <O>
vim.api.nvim_create_autocmd({ "FileType" }, {
  group = augroup("format_options"),
  pattern = { "*" },
  callback = function()
    vim.opt_local.fo:remove("o")
    vim.opt_local.fo:remove("r")
  end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "man",
    "grug-far",
    "help",
    "lspinfo",
    "notify",
    "qf",
    "startuptime",
    "checkhealth",
    "gitsigns.blame",
    "git",
    "fugitive",
    "fugitiveblame",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", {
      buffer = event.buf,
      silent = true,
      desc = "Quit buffer",
    })
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
  callback = function(args)
    if vim.g.vscode then
      return
    end

    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if client:supports_method("textDocument/foldingRange") then
      vim.o.foldexpr = "v:lua.vim.lsp.foldexpr()"
    else
      vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end
    if client:supports_method("textDocument/documentHighlight") then
      local highlight_augroup = vim.api.nvim_create_augroup("highlight", { clear = false })
      vim.api.nvim_create_autocmd({ "CursorHold" }, {
        buffer = args.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ "CursorHoldI", "CursorMoved", "CursorMovedI" }, {
        buffer = args.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })
    end

    -- setup diagnostics
    vim.diagnostic.config({
      virtual_text = {
        spacing = 4,
        source = "if_many",
        prefix = "●",
        severity = vim.diagnostic.severity.ERROR,
        current_line = true,
      },
      virtual_lines = false,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = "",
          [vim.diagnostic.severity.WARN] = "",
          [vim.diagnostic.severity.INFO] = "",
          [vim.diagnostic.severity.HINT] = "",
        },
        numhl = {
          [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
          [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
          [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
          [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
          [vim.diagnostic.severity.N] = "DiagnosticSignInfo",
        },
      },
      float = {
        border = "rounded",
        source = "if_many",
      },
    })
  end,
})

vim.api.nvim_create_autocmd("LspDetach", {
  group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
  callback = function(args)
    if vim.g.vscode then
      return
    end

    vim.api.nvim_clear_autocmds({ group = "highlight" })
    vim.lsp.buf.clear_references()
  end,
})
