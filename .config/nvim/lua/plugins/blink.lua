return {
  'saghen/blink.cmp',
  version = '1.*',
  opts = {
    sources = {
      default = function()
        local sources = { 'lsp', 'buffer' }
        local ok, node = pcall(vim.treesitter.get_node)

        if ok and node then
          if not vim.tbl_contains({ 'comment', 'line_comment', 'block_comment' }, node:type()) then
            table.insert(sources, 'path')
          end
          if node:type() ~= 'string' then
            table.insert(sources, 'snippets')
          end
        end

        return sources
      end,
    },
    fuzzy = { implementation = 'prefer_rust_with_warning' },
    snippets = { preset = 'luasnip' },
    cmdline = { enabled = false },
    completion = {
      list = { selection = { auto_insert = false } },
      menu = {
        draw = {
          columns = {
            { 'kind_icon', 'label', gap = 2 },
          },
        },
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 500,
      },
      ghost_text = { enabled = false },
    },
  },
  config = function(_, opts)
    require('blink.cmp').setup(opts)
  end,
}
