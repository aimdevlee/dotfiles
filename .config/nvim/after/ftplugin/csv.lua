--- CSV column header virtual text

local ns = vim.api.nvim_create_namespace('csv_header')

local COMMA = string.byte(',')
local QUOTE = string.byte('"')

--- Walk a CSV line and invoke a callback at each field boundary
---@param line string
---@param on_field fun(field_start: integer, field_end: integer, index: integer): boolean? return true to stop
local function walk_csv(line, on_field)
  local in_quotes = false
  local field_start = 1
  local index = 1

  for i = 1, #line do
    local b = line:byte(i)
    if b == QUOTE then
      in_quotes = not in_quotes
    elseif b == COMMA and not in_quotes then
      if on_field(field_start, i - 1, index) then
        return
      end
      index = index + 1
      field_start = i + 1
    end
  end
  on_field(field_start, #line, index)
end

--- Parse a CSV line into fields, handling quoted commas
---@param line string
---@return string[]
local function parse_csv_fields(line)
  local fields = {}
  walk_csv(line, function(field_start, field_end)
    local raw = line:sub(field_start, field_end)
    fields[#fields + 1] = raw:gsub('"', '')
  end)
  return fields
end

--- Count how many CSV columns exist before the cursor position
---@param line string
---@param col integer byte position (1-based)
---@return integer column index (1-based)
local function get_column_at(line, col)
  local result = 1
  walk_csv(line:sub(1, col), function(_, _, index)
    result = index
  end)
  return result
end

--- Find the byte offset where the current CSV field starts
---@param line string
---@param col_idx integer 1-based column index
---@return integer 0-based byte offset
local function get_field_offset(line, col_idx)
  local offset = 0
  walk_csv(line, function(field_start, _, index)
    if index == col_idx then
      offset = field_start - 1
      return true
    end
  end)
  return offset
end

--- Show CSV column header inline before the current field
local function update_csv_header()
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

  local row = vim.fn.line('.')
  if row <= 1 then
    return
  end

  local header_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
  if not header_line then
    return
  end

  local current_line = vim.api.nvim_get_current_line()
  local col_idx = get_column_at(current_line, vim.fn.col('.'))

  local headers = parse_csv_fields(header_line)
  local header = headers[col_idx]
  if not header then
    return
  end

  local offset = get_field_offset(current_line, col_idx)
  local label = vim.trim(header)

  vim.api.nvim_buf_set_extmark(0, ns, row - 1, offset, {
    virt_text = { { label .. ': ', 'Comment' } },
    virt_text_pos = 'inline',
  })
end

-- One group per buffer. A shared group with `clear = true` would wipe the
-- autocmd of every other CSV buffer each time this ftplugin runs.
local bufnr = vim.api.nvim_get_current_buf()

vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
  group = vim.api.nvim_create_augroup('ftplugin_csv_header_' .. bufnr, { clear = true }),
  buffer = bufnr,
  callback = update_csv_header,
})
