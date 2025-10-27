return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  config = function()
    --- @type snacks.Config
    require('snacks').setup({
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
          local excluded_filetypes = { 'markdown' }
          return vim.g.snacks_indent ~= false
            and vim.b[buf].snacks_indent ~= false
            and excluded_filetypes[vim.bo[buf].buftype] == nil
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
    })

    --- make transparent picker input bg
    Snacks.util.set_hl({ SnacksPickerInputCursorLine = 'None' })

    -- Setup keymaps for snacks features
    local map = vim.keymap.set

    -- stylua: ignore start
    -- Top Pickers & Explorer
    map("n", "<leader><space>", function() Snacks.picker.smart() end, { desc = "Smart Find Files" })
    map("n", "<leader>:", function() Snacks.picker.command_history() end, { desc = "Command History" })
    map("n", "<leader>n", function() Snacks.picker.notifications() end, { desc = "Notification History" })
    map("n", "<leader>e", function() Snacks.explorer.reveal({file = vim.fn.expand('%')}) end, { desc = "File Explorer" })

    -- find
    map("n", "<leader>fb", function() Snacks.picker.buffers() end, { desc = "Buffers" })
    map("n", "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, { desc = "Find Config File" })
    map("n", "<leader>ff", function() Snacks.picker.files() end, { desc = "Find Files" })
    map("n", "<leader>fg", function() Snacks.picker.grep() end, { desc = "Grep" })
    map("n", "<leader>fp", function() Snacks.picker.projects() end, { desc = "Projects" })
    map("n", "<leader>fr", function() Snacks.picker.recent() end, { desc = "Recent" })

    -- git
    map("n", "<leader>gb", function() Snacks.picker.git_branches() end, { desc = "Git Branches" })
    map("n", "<leader>gl", function() Snacks.picker.git_log() end, { desc = "Git Log" })
    map("n", "<leader>gL", function() Snacks.picker.git_log_line() end, { desc = "Git Log Line" })
    map("n", "<leader>gs", function() Snacks.picker.git_status() end, { desc = "Git Status" })
    map("n", "<leader>gS", function() Snacks.picker.git_stash() end, { desc = "Git Stash" })
    map("n", "<leader>gd", function() Snacks.picker.git_diff() end, { desc = "Git Diff (Hunks)" })
    map("n", "<leader>gf", function() Snacks.picker.git_files() end, { desc = "Git Files" })

    -- serch & grep
    map("n", "<leader>sb", function() Snacks.picker.lines() end, { desc = "Buffer Lines" })
    map("n", "<leader>sB", function() Snacks.picker.grep_buffers() end, { desc = "Grep Open Buffers" })
    map("n", "<leader>sg", function() Snacks.picker.grep() end, { desc = "Grep" })
    map({ "n", "x" }, "<leader>sw", function() Snacks.picker.grep_word() end, { desc = "Visual selection or word" })
    map("n", '<leader>s"', function() Snacks.picker.registers() end, { desc = "Registers" })
    map("n", '<leader>s/', function() Snacks.picker.search_history() end, { desc = "Search History" })
    map("n", "<leader>sa", function() Snacks.picker.autocmds() end, { desc = "Autocmds" })
    map("n", "<leader>sc", function() Snacks.picker.commands() end, { desc = "Command History" })
    map("n", "<leader>sD", function() Snacks.picker.diagnostics() end, { desc = "Diagnostics" })
    map("n", "<leader>sd", function() Snacks.picker.diagnostics_buffer() end, { desc = "Buffer Diagnostics" })
    map("n", "<leader>sh", function() Snacks.picker.help() end, { desc = "Help Pages" })
    map("n", "<leader>sH", function() Snacks.picker.highlights() end, { desc = "Highlights" })
    map("n", "<leader>si", function() Snacks.picker.icons() end, { desc = "Icons" })
    map("n", "<leader>sj", function() Snacks.picker.jumps() end, { desc = "Jumps" })
    map("n", "<leader>sk", function() Snacks.picker.keymaps() end, { desc = "Keymaps" })
    map("n", "<leader>sl", function() Snacks.picker.loclist() end, { desc = "Location List" })
    map("n", "<leader>sm", function() Snacks.picker.marks() end, { desc = "Marks" })
    map("n", "<leader>sM", function() Snacks.picker.man() end, { desc = "Man Pages" })
    map("n", "<leader>sp", function() Snacks.picker.lazy() end, { desc = "Search for Plugin Spec" })
    map("n", "<leader>sq", function() Snacks.picker.qflist() end, { desc = "Quickfix List" })
    map("n", "<leader>sR", function() Snacks.picker.resume() end, { desc = "Resume" })
    map("n", "<leader>su", function() Snacks.picker.undo() end, { desc = "Undo History" })

    -- LSP
    map("n", "grd", function() Snacks.picker.lsp_definitions() end, { desc = "Goto Definition" })
    map("n", "grD", function() Snacks.picker.lsp_declarations() end, { desc = "Goto Declaration" })
    map("n", "grr", function() Snacks.picker.lsp_references() end, { desc = "References", nowait = true, })
    map("n", "gri", function() Snacks.picker.lsp_implementations() end, { desc = "Goto Implementation" })
    map("n", "grt", function() Snacks.picker.lsp_type_definitions() end, { desc = "Goto Type Definition" })
    map("n", "grs", function() vim.lsp.buf.document_symbol() end, { desc = "Goto Symbol" })
    map("n", "<leader>ss", function() Snacks.picker.lsp_symbols() end, { desc = "LSP Symbols" })
    map("n", "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, { desc = "LSP Workspace Symbols" })

    -- Other
    map("n", "<leader>z", function() Snacks.zen() end, { desc = "Toggle Zen Mode" })
    map("n", "<leader>Z", function() Snacks.zen.zoom() end, { desc = "Toggle Zoom" })
    map("n", "<leader>.", function() Snacks.scratch() end, { desc = "Toggle Scratch Buffer" })
    map("n", "<leader>S", function() Snacks.scratch.select() end, { desc = "Select Scratch Buffer" })
    map("n", "<leader>n", function() Snacks.notifier.show_history() end, { desc = "Notification History" })
    map("n", "<leader>cR", function() Snacks.rename.rename_file() end, { desc = "Rename File" })
    map({ "n", "v" }, "<leader>gB", function() Snacks.gitbrowse() end, { desc = "Git Browse" })
    map("n", "<leader>gg", function() Snacks.lazygit() end, { desc = "Lazygit" })
    map("n", "<c-/>", function() Snacks.terminal() end, { desc = "Toggle Terminal" })
    -- stylua: ignore end
  end,
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
      end,
    })
  end,
}
