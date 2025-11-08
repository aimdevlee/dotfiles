local M = {}

local DEFAULT_COLORS = {
  normal = 0xc0caf5,
  comment = 0x565f89,
  string = 0x9ece6a,
  warning = 0xe0af68,
}

local MAX_PATH_LENGTH = 30

M.config = {
  excluded_filetypes = {
    'dashboard',
    'snacks_dashboard',
    'lazy',
    'mason',
    'help',
    'oil',
  },
  excluded_buftypes = {
    'nofile',
    'prompt',
    'terminal',
  },
}

local function get_hl_color(name, default)
  return vim.api.nvim_get_hl(0, { name = name }).fg or default
end

local function setup_highlights()
  local colors = {
    normal = get_hl_color('Normal', DEFAULT_COLORS.normal),
    comment = get_hl_color('Comment', DEFAULT_COLORS.comment),
    string = get_hl_color('String', DEFAULT_COLORS.string),
    warning = get_hl_color('WarningMsg', DEFAULT_COLORS.warning),
  }

  local highlights = {
    WinBar = { bg = 'NONE', fg = colors.normal },
    WinBarPath = { bg = 'NONE', fg = colors.comment, italic = true },
    WinBarFilename = { bg = 'NONE', fg = colors.string, bold = true },
    WinBarModified = { bg = 'NONE', fg = colors.warning, bold = true },
  }

  for name, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

local function is_floating_window()
  local win_config = vim.api.nvim_win_get_config(0)
  return win_config.relative ~= ''
end

local function should_exclude()
  if is_floating_window() then
    return true
  end

  return vim.tbl_contains(M.config.excluded_filetypes, vim.bo.filetype)
    or vim.tbl_contains(M.config.excluded_buftypes, vim.bo.buftype)
end

local function trim_path(path)
  if #path <= MAX_PATH_LENGTH then
    return path
  end

  local parts = vim.split(path, '/')
  local trimmed = {}
  local length = 0

  for i = #parts, 1, -1 do
    length = length + #parts[i] + 1
    if length > MAX_PATH_LENGTH then
      table.insert(trimmed, 1, '...')
      break
    end
    table.insert(trimmed, 1, parts[i])
  end

  return table.concat(trimmed, '/')
end

local function format_path(filepath)
  if filepath == '.' then
    return ''
  end
  return trim_path(filepath .. '/')
end

local function build_winbar_string(path, filename)
  local parts = { '%=' }

  if path ~= '' then
    table.insert(parts, '%#WinBarPath#' .. path)
  end

  table.insert(parts, '%#WinBarFilename#' .. filename)
  table.insert(parts, ' %#WinBarModified#%m')
  table.insert(parts, '%=')

  return table.concat(parts)
end

function M.render()
  if should_exclude() then
    return ''
  end

  local filename = vim.fn.expand('%:t')
  if filename == '' then
    return '%=%#WinBarFilename#[No Name]%='
  end

  local filepath = vim.fn.expand('%:~:.:h')
  local path = format_path(filepath)

  return build_winbar_string(path, filename)
end

local function setup_autocmds()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('winbar_highlights', { clear = true }),
    callback = setup_highlights,
  })

  vim.api.nvim_create_autocmd({ 'BufWinEnter', 'FileType' }, {
    group = vim.api.nvim_create_augroup('winbar_render', { clear = true }),
    callback = function()
      local ok, win_config = pcall(vim.api.nvim_win_get_config, 0)
      if ok and win_config.relative ~= '' then
        vim.wo.winbar = nil
        return
      end

      vim.wo.winbar = "%{%v:lua.require'winbar'.render()%}"
    end,
  })
end

setup_highlights()
setup_autocmds()

return M
