-- Statusline module

local M = {}

-- Configuration
M.config = {
  excluded_filetypes = {
    'dashboard',
    'snacks_dashboard',
    'lazy',
    'mason',
    'help',
  },
  excluded_buftypes = {
    'nofile',
    'prompt',
    'terminal',
  },
}

-- Setup highlight groups
local function setup_highlights()
  local normal_fg = vim.api.nvim_get_hl(0, { name = 'Normal' }).fg
  local comment_fg = vim.api.nvim_get_hl(0, { name = 'Comment' }).fg
  local error_fg = vim.api.nvim_get_hl(0, { name = 'DiagnosticError' }).fg
  local warn_fg = vim.api.nvim_get_hl(0, { name = 'DiagnosticWarn' }).fg
  local info_fg = vim.api.nvim_get_hl(0, { name = 'DiagnosticInfo' }).fg
  local hint_fg = vim.api.nvim_get_hl(0, { name = 'DiagnosticHint' }).fg
  local keyword_fg = vim.api.nvim_get_hl(0, { name = 'Keyword' }).fg

  -- Fallback colors (TokyoNight colors)
  normal_fg = normal_fg or 0xc0caf5
  comment_fg = comment_fg or 0x565f89
  error_fg = error_fg or 0xf7768e
  warn_fg = warn_fg or 0xe0af68
  info_fg = info_fg or 0x0db9d7
  hint_fg = hint_fg or 0x1abc9c
  keyword_fg = keyword_fg or 0x7dcfff

  vim.api.nvim_set_hl(0, 'StatusLine', { bg = 'NONE', fg = normal_fg })
  vim.api.nvim_set_hl(0, 'StatusLineMode', { bg = 'NONE', fg = keyword_fg, bold = true })
  vim.api.nvim_set_hl(0, 'StatusLineDiagError', { bg = 'NONE', fg = error_fg })
  vim.api.nvim_set_hl(0, 'StatusLineDiagWarn', { bg = 'NONE', fg = warn_fg })
  vim.api.nvim_set_hl(0, 'StatusLineDiagInfo', { bg = 'NONE', fg = info_fg })
  vim.api.nvim_set_hl(0, 'StatusLineDiagHint', { bg = 'NONE', fg = hint_fg })
  vim.api.nvim_set_hl(0, 'StatusLineInfo', { bg = 'NONE', fg = comment_fg })
end

-- Check if current buffer should show statusline
local function should_exclude()
  -- Check if window is floating
  local win_config = vim.api.nvim_win_get_config(0)
  if win_config.relative ~= '' then
    return true
  end

  local filetype = vim.bo.filetype
  local buftype = vim.bo.buftype

  return vim.tbl_contains(M.config.excluded_filetypes, filetype)
    or vim.tbl_contains(M.config.excluded_buftypes, buftype)
end

-- Render statusline string (called via v:lua)
function M.render()
  if should_exclude() then
    return ' '
  end

  -- Get mode
  local mode = vim.fn.mode()
  local mode_map = {
    -- Normal modes
    ['n'] = 'NORMAL',
    ['no'] = 'N-PENDING',
    ['nov'] = 'N-PENDING',
    ['noV'] = 'N-PENDING',
    ['no'] = 'N-PENDING',
    ['niI'] = 'NORMAL',
    ['niR'] = 'NORMAL',
    ['niV'] = 'NORMAL',
    ['nt'] = 'NORMAL',
    ['ntT'] = 'NORMAL',

    -- Visual modes
    ['v'] = 'VISUAL',
    ['vs'] = 'VISUAL',
    ['V'] = 'V-LINE',
    ['Vs'] = 'V-LINE',
    [''] = 'V-BLOCK',
    ['s'] = 'V-BLOCK',

    -- Select modes
    ['s'] = 'SELECT',
    ['S'] = 'S-LINE',
    [''] = 'S-BLOCK',

    -- Insert modes
    ['i'] = 'INSERT',
    ['ic'] = 'INSERT',
    ['ix'] = 'INSERT',

    -- Replace modes
    ['R'] = 'REPLACE',
    ['Rc'] = 'REPLACE',
    ['Rx'] = 'REPLACE',
    ['Rv'] = 'V-REPLACE',
    ['Rvc'] = 'V-REPLACE',
    ['Rvx'] = 'V-REPLACE',

    -- Command modes
    ['c'] = 'COMMAND',
    ['cv'] = 'EX',
    ['ce'] = 'EX',

    -- Terminal mode
    ['t'] = 'TERMINAL',

    -- Other modes
    ['r'] = 'PROMPT',
    ['rm'] = 'MORE',
    ['r?'] = 'CONFIRM',
    ['!'] = 'SHELL',
  }
  local mode_str = mode_map[mode] or mode:upper()

  -- Get diagnostics count
  local diagnostics = vim.diagnostic.get(0)
  local error_count = 0
  local warn_count = 0
  local info_count = 0
  local hint_count = 0
  for _, diag in ipairs(diagnostics) do
    if diag.severity == vim.diagnostic.severity.ERROR then
      error_count = error_count + 1
    elseif diag.severity == vim.diagnostic.severity.WARN then
      warn_count = warn_count + 1
    elseif diag.severity == vim.diagnostic.severity.INFO then
      info_count = info_count + 1
    elseif diag.severity == vim.diagnostic.severity.HINT then
      hint_count = hint_count + 1
    end
  end

  -- Build statusline string
  local result = ''
  result = result .. '%#StatusLineMode# ' .. mode_str .. ' '
  result = result .. '%=' -- Right align

  -- Show diagnostics individually (only if count > 0)
  local has_diag = false
  if error_count > 0 then
    result = result .. '%#StatusLineDiagError# ' .. error_count .. ' '
    has_diag = true
  end
  if warn_count > 0 then
    result = result .. '%#StatusLineDiagWarn# ' .. warn_count .. ' '
    has_diag = true
  end
  if info_count > 0 then
    result = result .. '%#StatusLineDiagInfo# ' .. info_count .. ' '
    has_diag = true
  end
  if hint_count > 0 then
    result = result .. '%#StatusLineDiagHint# ' .. hint_count .. ' '
    has_diag = true
  end

  if has_diag then
    result = result .. '%#StatusLine#│'
  end

  result = result .. '%#StatusLineInfo# %l:%c │ %p%% '

  return result
end

-- Initialize
setup_highlights()

-- Refresh highlights on colorscheme change
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('statusline_highlights', { clear = true }),
  callback = setup_highlights,
})

-- Set statusline using v:lua expression
vim.api.nvim_create_autocmd({ 'BufWinEnter', 'FileType', 'ModeChanged', 'DiagnosticChanged' }, {
  group = vim.api.nvim_create_augroup('statusline_render', { clear = true }),
  callback = function()
    -- Don't set statusline for floating windows
    local ok, win_config = pcall(vim.api.nvim_win_get_config, 0)
    if ok and win_config.relative ~= '' then
      return
    end

    vim.o.statusline = "%{%v:lua.require'statusline'.render()%}"
  end,
})

return M
