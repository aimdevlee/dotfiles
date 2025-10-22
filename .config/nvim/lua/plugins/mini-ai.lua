return {
  'nvim-mini/mini.ai',
  event = 'BufReadPre',
  config = function()
    require('mini.ai').setup({
      n_lines = 500, -- How many lines to search for textobject
    })
  end,
}

