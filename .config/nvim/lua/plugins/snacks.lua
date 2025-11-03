return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    animate = { fps = 240 },
    bigfile = { enabled = true },
    dashboard = {
      enabled = true,
      preset = {
        pick = 'fzf-lua',
        -- header = [[
        -- ]],
        keys = {
        -- stylua: ignore start
        { icon = "", key = "f", desc = "Find File",       action = ":lua Snacks.dashboard.pick('files')" },
        { icon = "", key = "n", desc = "New File",        action = ":ene | startinsert" },
        { icon = "", key = "g", desc = "Find Text",       action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = "", key = "r", desc = "Recent Files",    action = ":lua Snacks.dashboard.pick('oldfiles')" },
        { icon = "", key = "c", desc = "Config",          action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
        { icon = "", key = "s", desc = "Restore Session", section = "session" },
        { icon = "", key = "L", desc = "Lazy",            action = ":Lazy",                                                                enabled = package.loaded.lazy ~= nil },
        { icon = "", key = "q", desc = "Quit",            action = ":qa" },
          -- stylua: ignore end
        },
      },
    },
    gitbrowse = { enabled = true },
    git = { enabled = true },
    indent = {
      chunk = {
        enabled = true,
        only_current = false,
      },
      filter = function(buf, win)
        local excluded_filetypes = { 'markdown', 'wk' }
        return vim.g.snacks_indent ~= false
          and vim.b[buf].snacks_indent ~= false
          and vim.tbl_contains(excluded_filetypes, vim.b[buf].buftype)
      end,
    },
    input = { enabled = true },
    lazygit = { enabled = true },
    notifier = { enabled = true },
    picker = {
      enabled = true,
      layout = { fullscreen = false },
      formatters = {
        file = {
          truncate = 100,
          filename_first = false,
        },
      },
      sources = {
        explorer = {
          hidden = true,
        },
      },
    },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = false },
    statuscolumn = { enabled = true },
  },
  keys = {
    -- stylua: ignore start
    -- Top Pickers & Explorer
    {"<leader><space>", function() Snacks.picker.smart() end,  desc = "Smart Find Files" },
    {"<leader>:", function() Snacks.picker.command_history() end,  desc = "Command History" },
    {"<leader>n", function() Snacks.picker.notifications() end,  desc = "Notification History" },

    -- find
    {"<leader>fb", function() Snacks.picker.buffers() end,  desc = "Buffers" },
    {"<leader>fc", function() Snacks.picker.files( {cwd = vim.fn.stdpath("config")}) end, desc = "Find Config File" },
    {"<leader>ff", function() Snacks.picker.files() end,  desc = "Find Files" },
    {"<leader>fg", function() Snacks.picker.grep() end,  desc = "Grep" },
    {"<leader>fp", function() Snacks.picker.projects() end,  desc = "Projects" },
    {"<leader>fr", function() Snacks.picker.recent() end,  desc = "Recent" },

    -- git
    {"<leader>gb", function() Snacks.picker.git_branches() end,  desc = "Git Branches" },
    {"<leader>gl", function() Snacks.picker.git_log() end,  desc = "Git Log" },
    {"<leader>gL", function() Snacks.picker.git_log_line() end,  desc = "Git Log Line" },
    {"<leader>gs", function() Snacks.picker.git_status() end,  desc = "Git Status" },
    {"<leader>gS", function() Snacks.picker.git_stash() end,  desc = "Git Stash" },
    {"<leader>gd", function() Snacks.picker.git_diff() end,  desc = "Git Diff (Hunks)" },
    {"<leader>gf", function() Snacks.picker.git_files() end,  desc = "Git Files" },

    -- serch & grep
    {"<leader>sb", function() Snacks.picker.lines() end,  desc = "Buffer Lines" },
    {"<leader>sB", function() Snacks.picker.grep_buffers() end,  desc = "Grep Open Buffers" },
    {"<leader>sg", function() Snacks.picker.grep() end,  desc = "Grep" },
    {"<leader>sw", function() Snacks.picker.grep_word() end, mode = "x", desc = "Visual selection or word" },
    {'<leader>s"', function() Snacks.picker.registers() end,  desc = "Registers" },
    {'<leader>s/', function() Snacks.picker.search_history() end,  desc = "Search History" },
    {"<leader>sa", function() Snacks.picker.autocmds() end,  desc = "Autocmds" },
    {"<leader>sc", function() Snacks.picker.commands() end,  desc = "Command History" },
    {"<leader>sD", function() Snacks.picker.diagnostics() end,  desc = "Diagnostics" },
    {"<leader>sd", function() Snacks.picker.diagnostics_buffer() end,  desc = "Buffer Diagnostics" },
    {"<leader>sh", function() Snacks.picker.help() end,  desc = "Help Pages" },
    {"<leader>sH", function() Snacks.picker.highlights() end,  desc = "Highlights" },
    {"<leader>si", function() Snacks.picker.icons() end,  desc = "Icons" },
    {"<leader>sj", function() Snacks.picker.jumps() end,  desc = "Jumps" },
    {"<leader>sk", function() Snacks.picker.keymaps() end,  desc = "Keymaps" },
    {"<leader>sl", function() Snacks.picker.loclist() end,  desc = "Location List" },
    {"<leader>sm", function() Snacks.picker.marks() end,  desc = "Marks" },
    {"<leader>sM", function() Snacks.picker.man() end,  desc = "Man Pages" },
    {"<leader>sp", function() Snacks.picker.lazy() end,  desc = "Search for Plugin Spec" },
    {"<leader>sq", function() Snacks.picker.qflist() end,  desc = "Quickfix List" },
    {"<leader>sR", function() Snacks.picker.resume() end,  desc = "Resume" },
    {"<leader>su", function() Snacks.picker.undo() end,  desc = "Undo History" },

    -- LSP
    {"grd", function() Snacks.picker.lsp_definitions() end,  desc = "Goto Definition" },
    {"grD", function() Snacks.picker.lsp_declarations() end,  desc = "Goto Declaration" },
    {"grr", function() Snacks.picker.lsp_references() end,  desc = "References", nowait = true, },
    {"gri", function() Snacks.picker.lsp_implementations() end,  desc = "Goto Implementation" },
    {"grt", function() Snacks.picker.lsp_type_definitions() end,  desc = "Goto Type Definition" },
    {"grs", function() vim.lsp.buf.document_symbol() end,  desc = "Goto Symbol" },
    {"<leader>ss", function() Snacks.picker.lsp_symbols() end,  desc = "LSP Symbols" },
    {"<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end,  desc = "LSP Workspace Symbols" },

    -- Other
    {"<leader>z", function() Snacks.zen() end,  desc = "Toggle Zen Mode" },
    {"<leader>Z", function() Snacks.zen.zoom() end,  desc = "Toggle Zoom" },
    {"<leader>.", function() Snacks.scratch() end,  desc = "Toggle Scratch Buffer" },
    {"<leader>S", function() Snacks.scratch.select() end,  desc = "Select Scratch Buffer" },
    {"<leader>n", function() Snacks.notifier.show_history() end,  desc = "Notification History" },
    {"<leader>cR", function() Snacks.rename.rename_file() end,  desc = "Rename File" },
    { "<leader>gB", function() Snacks.gitbrowse() end,  desc = "Git Browse" },
    {"<leader>gg", function() Snacks.lazygit() end,  desc = "Lazygit" },
    {"<c-/>", function() Snacks.terminal() end,  desc = "Toggle Terminal" },
    -- stylua: ignore end
  },
  init = function()
    vim.api.nvim_create_autocmd('User', {
      pattern = 'VeryLazy',
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        _G.bt = function()
          Snacks.debug.backtrace()
        end

        vim.print = _G.dd

        -- Create some toggle mappings
        Snacks.toggle.option('wrap', { name = 'Wrap' }):map('<leader>tw')
        Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):map('<leader>tr')
        Snacks.toggle.diagnostics():map('<leader>td')
        Snacks.toggle.line_number():map('<leader>tl')
        Snacks.toggle
          .option('conceallevel', { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
          :map('<leader>tc')
        Snacks.toggle.treesitter():map('<leader>tT')
        Snacks.toggle.option('background', { off = 'light', on = 'dark', name = 'Dark Background' }):map('<leader>tb')
        Snacks.toggle.inlay_hints():map('<leader>th')
        Snacks.toggle.indent():map('<leader>ti')
        Snacks.toggle.dim():map('<leader>tD')
        local format_on_save = Snacks.toggle.new({
          id = 'format_on_save',
          name = 'Format on save',
          get = function()
            return not vim.g.disable_autoformat
          end,
          set = function(state)
            vim.g.disable_autoformat = not state
          end,
        })
        format_on_save:map('<leader>tf')

        --- make transparent picker input bg
        Snacks.util.set_hl({ SnacksPickerInputCursorLine = 'None' })
      end,
    })
    vim.api.nvim_create_user_command('BareLazyGit', function()
      Snacks.lazygit({ args = { '--git-dir=' .. os.getenv('HOME') .. '/.cfg', '--work-tree=' .. os.getenv('HOME') } })
    end, {})
  end,
}
