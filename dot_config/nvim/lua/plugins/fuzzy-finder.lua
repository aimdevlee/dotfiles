return {
  {
    "nvim-telescope/telescope.nvim",
    event = "VimEnter",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = "make",

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
      { "nvim-telescope/telescope-ui-select.nvim" },
    },
    keys = function()
      local builtin = require("telescope.builtin")

      return {
        { "<leader>sk", builtin.keymaps, desc = "keymaps" },
        { "<leader>ff", builtin.find_files, desc = "find files" },
        {
          "<leader>fb",
          function()
            builtin.buffers(require("telescope.themes").get_dropdown({
              -- winblend = 10,
              previewer = false,
            }))
          end,
          desc = "buffers",
        },
        { "<leader>fg", builtin.git_files, desc = "git" },
        { "<leader>fr", builtin.oldfiles, desc = "recent" },
        { "<leader>.", builtin.resume, desc = "resume" },
        { "<leader>sg", builtin.live_grep, desc = "live grep" },
        {
          "<leader>sc",
          function()
            builtin.find_files({ cwd = vim.fn.stdpath("config") })
          end,
          desc = "config",
        },
        { "<leader>w", proxy = "<c-w>", group = "windows" },
        -- { "<leader>sc", require("telescope").extensions.chezmoi.find_files, desc = "chezmoi" },
      }
    end,
    config = function(opts)
      local truncate_home_path = function(opts, path)
        local home = os.getenv("HOME")
        local pattern = "^" .. Util.escape_string(home) .. "/"
        local stripped = string.gsub(path, pattern, "")
        return stripped
      end

      require("telescope").setup({
        defaults = {
          path_display = truncate_home_path,
        },
        pickers = {
          lsp_references = {
            entry_maker = function(entry)
              local displayer = require("telescope.pickers.entry_display").create({
                items = {
                  { width = #truncate_home_path({}, entry.filename) },
                  { remaining = true },
                },
                separator = ":",
              })

              local make_display = function(entry)
                return displayer({
                  {
                    string.format("%s:%d:%d", truncate_home_path({}, entry.filename), entry.lnum, entry.col),
                    "", -- highlight
                  },
                  entry.text:gsub(".* | ", ""),
                })
              end

              return {
                value = entry,
                display = make_display,
                ordinal = entry.filename .. " " .. entry.text,
                filename = entry.filename,
                text = entry.text,
                lnum = entry.lnum,
                col = entry.col,
                start = entry.start,
                finish = entry.finish,
              }
            end,
          },
        },
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown(),
          },
        },
      })

      -- Enable Telescope extensions if they are installed
      pcall(require("telescope").load_extension, "fzf")
      pcall(require("telescope").load_extension, "ui-select")
      pcall(require("telescope").load_extension, "chezmoi")
    end,
  },
}
