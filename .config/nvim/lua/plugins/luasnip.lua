return {

  'L3MON4D3/LuaSnip',
  version = 'v2.*',
  build = 'make install_jsregexp',
  dependencies = { 'rafamadriz/friendly-snippets' },
  keys = {
    {
      '<C-r>s',
      '<cmd>lua require(\'luasnip.extras.otf\').on_the_fly("s")<CR>',
      desc = 'Insert on-the-fly snippet',
      mode = 'i',
    },
    {
      '<C-s>',
      '"sc<cmd>lua require(\'luasnip.extras.otf\').on_the_fly("s")<CR>',
      desc = 'Insert on-the-fly snippet',
      mode = 'v',
    },
  },
  config = function()
    local luasnip = require('luasnip')
    local types = require('luasnip.util.types')
    local config = {
      -- Check if the current snippet was deleted.
      delete_check_events = 'TextChanged',
      -- Display a cursor-like placeholder in unvisited nodes
      -- of the snippet.
      ext_opts = {
        [types.insertNode] = {
          unvisited = {
            virt_text = { { '|', 'Conceal' } },
            virt_text_pos = 'inline',
          },
        },
        [types.exitNode] = {
          unvisited = {
            virt_text = { { '|', 'Conceal' } },
            virt_text_pos = 'inline',
          },
        },
        [types.choiceNode] = {
          active = {
            virt_text = { { '(snippet) choice node', 'LspInlayHint' } },
          },
        },
      },
      enable_autosnippets = true,
    }
    luasnip.setup(config)
    require('luasnip.loaders.from_vscode').lazy_load({
      -- paths = vim.fn.stdpath('config') .. '/snippets',
    })
    vim.keymap.set({ 'i', 's' }, '<C-c>', function()
      if luasnip.choice_active() then
        require('luasnip.extras.select_choice')()
      end
    end, { desc = 'Select choice' })
  end,
}
