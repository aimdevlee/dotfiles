-- Winbar module

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
  local string_fg = vim.api.nvim_get_hl(0, { name = 'String' }).fg
  local warning_fg = vim.api.nvim_get_hl(0, { name = 'WarningMsg' }).fg

  -- Fallback colors
  normal_fg = normal_fg or 0xc0caf5
  comment_fg = comment_fg or 0x565f89
  string_fg = string_fg or 0x9ece6a
  warning_fg = warning_fg or 0xe0af68

  vim.api.nvim_set_hl(0, 'WinBar', { bg = 'NONE', fg = normal_fg })
  vim.api.nvim_set_hl(0, 'WinBarPath', { bg = 'NONE', fg = comment_fg, italic = true })
  vim.api.nvim_set_hl(0, 'WinBarFilename', { bg = 'NONE', fg = string_fg, bold = true })
  vim.api.nvim_set_hl(0, 'WinBarModified', { bg = 'NONE', fg = warning_fg, bold = true })
end

-- Check if current buffer should show winbar
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

-- Render winbar string (called via v:lua)
function M.render()
  if should_exclude() then
    return ''
  end

  local filepath = vim.fn.expand('%:~:.:h')
  local filename = vim.fn.expand('%:t')

  if filename == '' then
    return ''
  end

  -- Clean up filepath
  local path = ''
  if filepath ~= '.' then
    path = filepath .. '/'
  end

  -- trim path by '/' if too long
  local max_path_length = 30
  if #path > max_path_length then
    local parts = vim.split(path, '/')
    local trimmed_parts = {}
    local total_length = 0
    for i = #parts, 1, -1 do
      local part = parts[i]
      total_length = total_length + #part + 1 -- +1 for '/'
      if total_length > max_path_length then
        table.insert(trimmed_parts, 1, '...')
        break
      end
      table.insert(trimmed_parts, 1, part)
    end
    path = table.concat(trimmed_parts, '/')
  end

  -- Build winbar string
  local result = '%='
  if path ~= '' then
    result = result .. '%#WinBarPath#' .. path
  end
  result = result .. '%#WinBarFilename#' .. (filename ~= '' and filename or '[No Name]')
  result = result .. ' %#WinBarModified#%m'
  result = result .. '%='

  return result
end

-- Initialize
setup_highlights()

-- Refresh highlights on colorscheme change
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('winbar_highlights', { clear = true }),
  callback = setup_highlights,
})

-- Set winbar using v:lua expression
vim.api.nvim_create_autocmd({ 'BufWinEnter', 'FileType' }, {
  group = vim.api.nvim_create_augroup('winbar_render', { clear = true }),
  callback = function()
    -- Don't set winbar for floating windows
    local ok, win_config = pcall(vim.api.nvim_win_get_config, 0)
    if ok and win_config.relative ~= '' then
      vim.wo.winbar = nil
      return
    end

    vim.wo.winbar = "%{%v:lua.require'winbar'.render()%}"
  end,
})

return M
