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

-- Default fallback colors (TokyoNight theme)
local FALLBACK_COLORS = {
  normal = 0xc0caf5,
  comment = 0x565f89,
  error = 0xf7768e,
  warn = 0xe0af68,
  info = 0x0db9d7,
  hint = 0x1abc9c,
  keyword = 0x7dcfff,
}

-- Mode mappings
local MODE_MAP = {
  -- Normal modes
  n = 'NORMAL',
  no = 'N-PENDING',
  nov = 'N-PENDING',
  noV = 'N-PENDING',
  niI = 'NORMAL',
  niR = 'NORMAL',
  niV = 'NORMAL',
  nt = 'NORMAL',
  ntT = 'NORMAL',

  -- Visual modes
  v = 'VISUAL',
  vs = 'VISUAL',
  V = 'V-LINE',
  Vs = 'V-LINE',
  [''] = 'V-BLOCK',
  ['s'] = 'V-BLOCK',

  -- Select modes
  s = 'SELECT',
  S = 'S-LINE',

  -- Insert modes
  i = 'INSERT',
  ic = 'INSERT',
  ix = 'INSERT',

  -- Replace modes
  R = 'REPLACE',
  Rc = 'REPLACE',
  Rx = 'REPLACE',
  Rv = 'V-REPLACE',
  Rvc = 'V-REPLACE',
  Rvx = 'V-REPLACE',

  -- Command modes
  c = 'COMMAND',
  cv = 'EX',
  ce = 'EX',

  -- Terminal mode
  t = 'TERMINAL',

  -- Other modes
  r = 'PROMPT',
  rm = 'MORE',
  ['r?'] = 'CONFIRM',
  ['!'] = 'SHELL',
}

-- Get highlight color with fallback
local function get_hl_color(name, fallback)
  local hl = vim.api.nvim_get_hl(0, { name = name })
  return hl.fg or fallback
end

-- Setup highlight groups
local function setup_highlights()
  local colors = {
    normal = get_hl_color('Normal', FALLBACK_COLORS.normal),
    comment = get_hl_color('Comment', FALLBACK_COLORS.comment),
    error = get_hl_color('DiagnosticError', FALLBACK_COLORS.error),
    warn = get_hl_color('DiagnosticWarn', FALLBACK_COLORS.warn),
    info = get_hl_color('DiagnosticInfo', FALLBACK_COLORS.info),
    hint = get_hl_color('DiagnosticHint', FALLBACK_COLORS.hint),
    keyword = get_hl_color('Keyword', FALLBACK_COLORS.keyword),
  }

  vim.api.nvim_set_hl(0, 'StatusLine', { bg = 'NONE', fg = colors.normal })
  vim.api.nvim_set_hl(0, 'StatusLineMode', { bg = 'NONE', fg = colors.keyword, bold = true })
  vim.api.nvim_set_hl(0, 'StatusLineDiagError', { bg = 'NONE', fg = colors.error })
  vim.api.nvim_set_hl(0, 'StatusLineDiagWarn', { bg = 'NONE', fg = colors.warn })
  vim.api.nvim_set_hl(0, 'StatusLineDiagInfo', { bg = 'NONE', fg = colors.info })
  vim.api.nvim_set_hl(0, 'StatusLineDiagHint', { bg = 'NONE', fg = colors.hint })
  vim.api.nvim_set_hl(0, 'StatusLineInfo', { bg = 'NONE', fg = colors.comment })
end

-- Check if current buffer should show statusline
local function should_exclude()
  local win_config = vim.api.nvim_win_get_config(0)
  if win_config.relative ~= '' then
    return true
  end

  local filetype = vim.bo.filetype
  local buftype = vim.bo.buftype

  return vim.tbl_contains(M.config.excluded_filetypes, filetype)
    or vim.tbl_contains(M.config.excluded_buftypes, buftype)
end

-- Get current mode string
local function get_mode_string()
  local mode = vim.fn.mode()
  return MODE_MAP[mode] or mode:upper()
end

-- Get Git branch name
local function get_git_branch()
  local branch = vim.fn.system("git branch --show-current 2>/dev/null | tr -d '\n'")
  if vim.v.shell_error ~= 0 or branch == '' then
    return nil
  end
  return branch
end

-- Get active LSP clients
local function get_lsp_clients()
  local buf = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = buf })

  if #clients == 0 then
    return nil
  end

  local names = {}
  for _, client in ipairs(clients) do
    table.insert(names, client.name)
  end

  return table.concat(names, ', ')
end

-- Get search count information
local function get_search_count()
  if vim.v.hlsearch == 0 then
    return nil
  end

  local ok, search = pcall(vim.fn.searchcount, { recompute = 1, maxcount = -1 })
  if not ok or search.current == nil or search.total == 0 then
    return nil
  end

  return string.format('%d/%d', search.current, search.total)
end

-- Get diagnostic counts for current buffer
local function get_diagnostic_counts()
  local diagnostics = vim.diagnostic.get(0)
  local counts = { error = 0, warn = 0, info = 0, hint = 0 }

  for _, diag in ipairs(diagnostics) do
    if diag.severity == vim.diagnostic.severity.ERROR then
      counts.error = counts.error + 1
    elseif diag.severity == vim.diagnostic.severity.WARN then
      counts.warn = counts.warn + 1
    elseif diag.severity == vim.diagnostic.severity.INFO then
      counts.info = counts.info + 1
    elseif diag.severity == vim.diagnostic.severity.HINT then
      counts.hint = counts.hint + 1
    end
  end

  return counts
end

-- Render diagnostic section
local function render_diagnostics(counts)
  local result = ''
  local has_diag = false

  local items = {
    { count = counts.error, hl = 'StatusLineDiagError' },
    { count = counts.warn, hl = 'StatusLineDiagWarn' },
    { count = counts.info, hl = 'StatusLineDiagInfo' },
    { count = counts.hint, hl = 'StatusLineDiagHint' },
  }

  for _, item in ipairs(items) do
    if item.count > 0 then
      result = result .. string.format('%%#%s# %d ', item.hl, item.count)
      has_diag = true
    end
  end

  if has_diag then
    result = result .. '%#StatusLineInfo#│'
  end

  return result
end

-- Render statusline string (called via v:lua)
function M.render()
  if should_exclude() then
    return ' '
  end

  local components = {}

  -- Left side: Mode
  local mode_str = get_mode_string()
  table.insert(components, string.format('%%#StatusLineMode# %s ', mode_str))

  -- Git branch
  local branch = get_git_branch()
  if branch then
    table.insert(components, string.format('%%#StatusLineInfo# %s ', branch))
  end

  -- Center: Separator
  table.insert(components, '%=')

  -- Right side

  -- LSP clients
  local lsp = get_lsp_clients()
  if lsp then
    table.insert(components, string.format('%%#StatusLineInfo#[%s] │', lsp))
  end

  -- Search count
  local search = get_search_count()
  if search then
    table.insert(components, string.format('%%#StatusLineInfo#%s │', search))
  end

  -- Diagnostics
  local diag_counts = get_diagnostic_counts()
  table.insert(components, '%#StatusLineInfo#' .. render_diagnostics(diag_counts))

  -- Cursor position
  table.insert(components, '%#StatusLineInfo# %l:%c │ %p%% ')

  return table.concat(components)
end

-- Setup autocommands
local function setup_autocommands()
  local augroup_highlights = vim.api.nvim_create_augroup('statusline_highlights', { clear = true })
  local augroup_render = vim.api.nvim_create_augroup('statusline_render', { clear = true })

  -- Refresh highlights on colorscheme change
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = augroup_highlights,
    callback = setup_highlights,
  })

  -- Update statusline on relevant events
  vim.api.nvim_create_autocmd({
    'BufWinEnter',
    'FileType',
    'ModeChanged',
    'DiagnosticChanged',
    'LspAttach',
    'LspDetach',
    'CmdlineLeave',
  }, {
    group = augroup_render,
    callback = function()
      local ok, win_config = pcall(vim.api.nvim_win_get_config, 0)
      if ok and win_config.relative ~= '' then
        return
      end

      vim.o.statusline = "%{%v:lua.require'statusline'.render()%}"
    end,
  })
end

-- Initialize module
setup_highlights()
setup_autocommands()

return M
