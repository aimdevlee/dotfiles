return {
  {
    "kevinhwang91/nvim-ufo",
    lazy = false,
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

      vim.o.foldcolumn = "1"
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99

      local ftMap = {
        vim = "indent",
        python = { "indent" },
        git = "",
        dashboard = "",
        snacks_dashboard = "",
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
}
