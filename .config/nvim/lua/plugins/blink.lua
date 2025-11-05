return {
  'saghen/blink.cmp',
  version = '1.*',
  opts = {
    sources = {
      default = function()
        local sources = { 'lazydev', 'lsp', 'buffer' }
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
      providers = {
        lazydev = {
          name = 'LazyDev',
          module = 'lazydev.integrations.blink',
          -- make lazydev completions top priority (see `:h blink.cmp`)
          score_offset = 100,
        },
      },
    },
    fuzzy = { implementation = 'prefer_rust_with_warning' },
    snippets = { preset = 'luasnip' },
    cmdline = { enabled = true },
    completion = {
      list = { selection = { auto_insert = false } },
      menu = {
        draw = {
          columns = {
            { 'kind_icon', 'label', gap = 2 },
            { 'source_name', align = 'right' },
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
