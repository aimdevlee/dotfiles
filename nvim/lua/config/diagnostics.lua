local DIAGNOSTICS_DISABLED = {
  "lazy",
}

vim.diagnostic.config({
  -- virtual_text = {
  --   spacing = 4,
  --   source = "if_many",
  --   prefix = "●",
  --   format = function(diagnostic)
  --     if vim.fn.line(".") == diagnostic.lnum + 1 then
  --       return nil
  --     end
  --
  --     return diagnostic.message
  --   end,
  -- },
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

vim.api.nvim_create_autocmd({ "CursorMoved", "ModeChanged" }, {
  callback = function()
    if vim.tbl_contains(DIAGNOSTICS_DISABLED, vim.bo.filetype) then
      return nil
    end

    local current_line = vim.fn.line(".")

    -- Check if the cursor has moved to a different line
    if current_line ~= last_line then
      vim.diagnostic.hide()
      vim.diagnostic.show()
    end

    -- Update the last_line variable
    last_line = current_line

    local current_mode = vim.fn.mode()
    if current_mode == "v" or current_mode == "V" or current_mode == "\22" then
      -- hide diagnostics line in visual mode
      vim.diagnostic.hide()
    else
      vim.diagnostic.show()
    end
  end,
})

-- Re-render diagnostics when the window is resized

vim.api.nvim_create_autocmd("VimResized", {
  callback = function()
    vim.diagnostic.hide()
    vim.diagnostic.show()
  end,
})

-- Disable diagnostics
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function(event)
    -- DIAGNOSTICS_DIABLES has filetype then hide diagnostics
    if vim.tbl_contains(DIAGNOSTICS_DISABLED, vim.bo.filetype) then
      vim.diagnostic.hide()
      return nil
    end
  end,
})
