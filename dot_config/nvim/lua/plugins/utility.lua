return {
  {
    "kevinhwang91/nvim-ufo",
    event = "VeryLazy",
    dependencies = "kevinhwang91/promise-async",
    keys = {
      {
        "zR",
        function()
          require("ufo").openAllFolds()
        end,
        desc = "Open all folds",
      },
      {
        "zM",
        function()
          require("ufo").closeAllFolds()
        end,
        desc = "Close all folds",
      },
    },
    init = function()
      -- Need to disable zM, zR during init, because it will change foldlevel
      -- if zM/zR executed before the keymap settings of nvim-ufo has been effective.
      local ufo_not_ready = vim.schedule_wrap(function()
        vim.notify(
          "nvim-ufo is yet to be initialized, please try again later...",
          vim.log.levels.WARN,
          { timeout = 500, title = "nvim-ufo" }
        )
      end)
      vim.keymap.set("n", "zM", ufo_not_ready, { silent = true })
      vim.keymap.set("n", "zR", ufo_not_ready, { silent = true })
    end,
    config = function()
      local ufo = require("ufo")

      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99

      local ftMap = {
        vim = "indent",
        python = { "indent" },
        git = "",
        dashboard = "",
      }

      --- lsp -> treesitter -> indent
      ---@param bufnr number
      ---@return Promise
      local function customizeSelector(bufnr)
        local function handleFallbackException(err, providerName)
          if type(err) == "string" and err:match("UfoFallbackException") then
            return require("ufo").getFolds(bufnr, providerName)
          else
            return require("promise").reject(err)
          end
        end
        return require("ufo")
          .getFolds(bufnr, "lsp")
          :catch(function(err)
            return handleFallbackException(err, "treesitter")
          end)
          :catch(function(err)
            return handleFallbackException(err, "indent")
          end)
      end

      local opts = {
        open_fold_hl_timeout = 150,
        provider_selector = function(bufnr, filetype)
          return ftMap[filetype] or customizeSelector
        end,
        enable_get_fold_virt_text = true,
        fold_virt_text_handler = function(virt_text, lnum, end_lnum, width, truncate, ctx)
          local counts = (" ( %d)"):format(end_lnum - lnum + 1)
          local ellipsis = "⋯"
          local padding = ""

          ---@type string
          local end_text = vim.api.nvim_buf_get_lines(ctx.bufnr, end_lnum - 1, end_lnum, false)[1]
          ---@type UfoExtmarkVirtTextChunk[]
          local end_virt_text = ctx.get_fold_virt_text(end_lnum)

          -- Post-process end line: show only if it's a single word and token
          -- e.g., { ⋯ }  ( ⋯ )  [{( ⋯ )}]  function() ⋯ end  foo("bar", { ⋯ })
          -- Trim leading whitespaces in end_virt_text
          if #end_virt_text >= 1 and vim.trim(end_virt_text[1][1]) == "" then
            table.remove(end_virt_text, 1) -- e.g., {"   ", ")"} -> {")"}
          end

          -- if the end line consists of a single 'word' (not single token)
          -- this could be multiple tokens/chunks, e.g. `end)` `})`
          if #vim.split(vim.trim(end_text), " ") == 1 then
            if end_virt_text[1] ~= nil then
              end_virt_text[1][1] = vim.trim(end_virt_text[1][1]) -- trim the first token, e.g., "   }" -> "}"
            end
          else
            end_virt_text = {}
          end

          -- Process virtual text, with some truncation at virt_text
          local suffixWidth = (2 * vim.fn.strdisplaywidth(ellipsis)) + vim.fn.strdisplaywidth(counts)
          for _, v in ipairs(end_virt_text) do
            suffixWidth = suffixWidth + vim.fn.strdisplaywidth(v[1])
          end
          if suffixWidth > 10 then
            suffixWidth = 10
          end

          local target_width = width - suffixWidth
          local cur_width = 0

          -- the final virtual text tokens to display.
          local result = {}

          for _, chunk in ipairs(virt_text) do
            local chunk_text = chunk[1]

            local chunk_width = vim.fn.strdisplaywidth(chunk_text)
            if target_width > cur_width + chunk_width then
              table.insert(result, chunk)
            else
              chunk_text = truncate(chunk_text, target_width - cur_width)
              local hl_group = chunk[2]
              table.insert(result, { chunk_text, hl_group })
              chunk_width = vim.fn.strdisplaywidth(chunk_text)

              if cur_width + chunk_width < target_width then
                padding = padding .. (" "):rep(target_width - cur_width - chunk_width)
              end
              break
            end
            cur_width = cur_width + chunk_width
          end

          table.insert(result, { " " .. ellipsis .. " ", "UfoFoldedEllipsis" })

          -- Also truncate end_virt_text to suffixWidth.
          cur_width = 0
          local j = #result
          for i, v in ipairs(end_virt_text) do
            table.insert(result, v)
            cur_width = cur_width + #v[1]
            while cur_width > suffixWidth and j + 1 < #result do
              cur_width = cur_width - #result[j + 1][1]
              result[j + 1][1] = ""
              j = j + 1
            end
          end
          if cur_width > suffixWidth then
            local text = result[#result[1]][1]
            result[#result][1] = truncate(text, suffixWidth)
          end

          table.insert(result, { counts, "MoreMsg" })
          table.insert(result, { padding, "" })

          return result
        end,
      }

      ufo.setup(opts)
    end,
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true }, -- Optional
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },
    keys = {
      { "<leader>d", "<cmd>DBUIToggle<cr>", desc = "DBUI" },
    },
    init = function()
      -- Your DBUI configuration
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },
  {
    "rcarriga/nvim-notify",
    keys = {
      {
        "<leader>un",
        function()
          require("notify").dismiss({ silent = true, pending = true })
        end,
        desc = "Dismiss All Notifications",
      },
    },
    config = function()
      local opts = {
        stages = "static",
        timeout = 3000,
        max_height = function()
          return math.floor(vim.o.lines * 0.75)
        end,
        max_width = function()
          return math.floor(vim.o.columns * 0.75)
        end,
        on_open = function(win)
          vim.api.nvim_win_set_config(win, { zindex = 100 })
        end,
      }
      require("notify").setup(opts)
    end,
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    -- stylua: ignore
    keys = {
      { "<leader>sn", "", desc = "+noice"},
      { "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, mode = "c", desc = "Redirect Cmdline" },
      { "<leader>snl", function() require("noice").cmd("last") end, desc = "Noice Last Message" },
      { "<leader>snh", function() require("noice").cmd("history") end, desc = "Noice History" },
      { "<leader>sna", function() require("noice").cmd("all") end, desc = "Noice All" },
      { "<leader>snd", function() require("noice").cmd("dismiss") end, desc = "Dismiss All" },
      { "<leader>snt", function() require("noice").cmd("pick") end, desc = "Noice Picker (Telescope/FzfLua)" },
      { "<c-f>", function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end, silent = true, expr = true, desc = "Scroll Forward", mode = {"i", "n", "s"} },
      { "<c-b>", function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true, expr = true, desc = "Scroll Backward", mode = {"i", "n", "s"}},
    },
    config = function()
      -- HACK: noice shows messages from before it was enabled,
      -- but this is not ideal when Lazy is installing plugins,
      -- so clear the messages in this case.
      if vim.o.filetype == "lazy" then
        vim.cmd([[messages clear]])
      end

      local opts = {
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
        },
        routes = {
          {
            filter = {
              event = "msg_show",
              any = {
                { find = "%d+L, %d+B" },
                { find = "; after #%d+" },
                { find = "; before #%d+" },
              },
            },
            view = "mini",
          },
        },
        presets = {
          bottom_search = false,
          command_palette = true,
          long_message_to_split = true,
          lsp_doc_border = true,
        },
      }

      require("noice").setup(opts)
    end,
  },
  {
    "mistricky/codesnap.nvim",
    build = "make",
    -- keys = {
    --   { "<leader>cc", "<cmd>CodeSnap<cr>", mode = "x", desc = "clipboard" },
    --   { "<leader>cs", "<cmd>CodeSnapSave<cr>", mode = "x", desc = "file" },
    --   { "<leader>ca", "<cmd>CodeSnapASCII<cr>", mode = "x", desc = "ascii" },
    --   { "<leader>chc", "<cmd>CodeSnapHighlight<cr>", mode = "x", desc = "clipboard with highlight" },
    --   { "<leader>chs", "<cmd>CodeSnapHighlight<cr>", mode = "x", desc = "save with highlight" },
    -- },
    opts = {
      code_font_family = "Cica",
      save_path = "~/Pictures",
      has_breadcrumbs = true,
      bg_theme = "bamboo",
      has_line_number = true,
      watermark = "",
      bg_padding = 0,
    },
  },
}
