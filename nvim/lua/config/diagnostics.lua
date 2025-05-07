vim.diagnostic.config({
  virtual_text = {
    spacing = 4,
    source = "if_many",
    prefix = "●",
    format = function(diagnostic)
      if vim.fn.line(".") == diagnostic.lnum + 1 then
        return nil
      end

      return diagnostic.message
    end,
  },
  virtual_lines = {
    current_line = true,
  },
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
    },
  },
  float = {
    border = "rounded",
    source = "if_many",
  },
})

local last_line = vim.fn.line(".")

vim.api.nvim_create_autocmd({ "CursorMoved" }, {
  callback = function()
    local current_line = vim.fn.line(".")

    -- Check if the cursor has moved to a different line
    if current_line ~= last_line then
      vim.diagnostic.hide()
      vim.diagnostic.show()
    end

    -- Update the last_line variable
    last_line = current_line
  end,
})

-- Re-render diagnostics when the window is resized

vim.api.nvim_create_autocmd("VimResized", {
  callback = function()
    vim.diagnostic.hide()
    vim.diagnostic.show()
  end,
})
