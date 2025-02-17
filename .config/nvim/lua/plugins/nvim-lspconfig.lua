return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "williamboman/mason.nvim", config = true },
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    event = { "BufReadPost", "BufNewFile", "BufWritePre" },
    config = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
          end
          map("gd", require("telescope.builtin").lsp_definitions, "Lsp: definition")
          map("gD", vim.lsp.buf.declaration, "Lsp: declaration")
          map("gr", require("telescope.builtin").lsp_references, "Lsp: references")
          map("gi", require("telescope.builtin").lsp_implementations, "Lsp: implementation")
          map("<leader>st", require("telescope.builtin").lsp_type_definitions, "Lsp: type definition")
          -- Use aerial instead
          -- map("<leader>ss", require("telescope.builtin").lsp_document_symbols, "Lsp: document symbols")
          map("<leader>ss", "<cmd>Telescope aerial<cr>", "Goto Symbol (Aerial)")
          map("<leader>sS", function()
            require("telescope.builtin").lsp_dynamic_workspace_symbols()
          end, "Lsp: document symbols(workspace)")
          map("<leader>cr", vim.lsp.buf.rename, "Lsp: rename")
          map("<leader>ca", vim.lsp.buf.code_action, "Lsp: code action")
          -- Override by hover.nvim
          -- map("K", vim.lsp.buf.hover, "Hover Documentation")

          -- git
          map("<leader>gc", "<cmd>Telescope git_commits<CR>", "Commits")
          map("<leader>gs", "<cmd>Telescope git_status<CR>", "Status")
          local client = vim.lsp.get_client_by_id(event.data.client_id)

          -- document highlight
          if client and client.server_capabilities.documentHighlightProvider then
            local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd("LspDetach", {
              group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
              callback = function(event2)
                vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = event2.buf })
                vim.lsp.buf.clear_references()
              end,
            })
          end

          -- inlay hint
          if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
            vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
            -- map("<leader>th", function()
            --   vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
            -- end, "toggle Inlay hints")
          end

          -- diagnotics
          local diagnostics = {
            underline = true,
            update_in_insert = false,
            virtual_text = {
              spacing = 4,
              source = "if_many",
              -- prefix = function(diagnostic)
              --   local icons = Util.icons.diagnostics
              --   for d, icon in pairs(icons) do
              --     if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
              --       return icon
              --     end
              --   end
              -- end,
            },
            severity_sort = true,
            signs = {
              text = {
                -- [vim.diagnostic.severity.ERROR] = Util.icons.diagnostics.Error,
                -- [vim.diagnostic.severity.WARN] = Util.icons.diagnostics.Warn,
                -- [vim.diagnostic.severity.HINT] = Util.icons.diagnostics.Hint,
                -- [vim.diagnostic.severity.INFO] = Util.icons.diagnostics.Info,
              },
            },
          }

          -- define diagnostics signs
          for severity, icon in pairs(diagnostics.signs.text) do
            local name = vim.diagnostic.severity[severity]:lower():gsub("^%l", string.upper)
            name = "DiagnosticSign" .. name
            vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
          end

          vim.diagnostic.config(diagnostics)
        end,
      })

      local servers = {
        lua_ls = {
          -- cmd = {...},
          -- filetypes = { ...},
          -- capabilities = {},
          settings = {
            Lua = {
              completion = {
                callSnippet = "Replace",
              },
              -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
              -- diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
        ruby_lsp = {
          -- cmd_env = {
          --   BUNDLE_GEMFILE = "/Users/dongbin-lee/works/freee-payroll/.ruby-lsp/Gemfile",
          --   BUNDLE_PATH__SYSTEM = "true",
          -- },
          -- cmd = { "bundle", "exec", "ruby-lsp" },
          init_options = {
            formatter = "syntax_tree",
            -- enabledFeatures = {
            --   "codeActions",
            --   "diagnostics",
            --   "documentHighlights",
            --   "documentLink",
            --   "documentSymbols",
            --   "foldingRanges",
            --   "formatting",
            --   "hover",
            --   "inlayHint",
            --   "onTypeFormatting",
            --   "selectionRanges",
            --   "sementicHighlighting",
            --   "completion",
            --   "codeLens",
            --   "definition",
            --   "workspaceSymbol",
            --   "signatureHelp",
            --   "typeHierarchy",
            --   "completionResolve",
            -- },
          },
          -- capabilities = {}
          -- on_attach = function(client, bufnr)
          -- end
        },
        sorbet = {
          cmd = { "bundle", "exec", "srb", "tc", "--lsp" },
          on_attach = function(client, bufnr)
            if client.server_capabilities.sorbetShowSymbolProvider then
              vim.api.nvim_create_user_command("CopySymbolToClipboard", function()
                -- Get the current cursor position (1-based line, 0-based column)
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                local params = {
                  textDocument = { uri = "file://" .. vim.api.nvim_buf_get_name(0) },
                  -- Adjusting line number to match 0-based indexing for Sorbet's request.
                  -- ref. https://github.com/sorbet/sorbet/blob/c73f3beb911f551e789210190c087006f46614f2/main/lsp/json_types.cc#L191
                  position = { line = line - 1, character = col },
                }
                local result = client.request_sync("sorbet/showSymbol", params, 3000)

                -- copy symbol to clipboard
                for _, response in pairs(result) do
                  if response.name then
                    vim.fn.setreg("+", response.name)
                  end
                end
              end, {})
            end
          end,
        },
        ts_ls = {
          init_options = {
            hostInfo = "neovim",
            -- plugins = {},
            -- tsserver = {},
            preferences = {
              includeInlayParameterNameHints = "all",
            },
          },
        },
        -- use ts_ls instead of vtsls, but keeps its configuration
        -- vtsls = {
        --   filetypes = {
        --     "javascript",
        --     "javascriptreact",
        --     "javascript.jsx",
        --     "typescript",
        --     "typescriptreact",
        --     "typescript.tsx",
        --   },
        --   settings = {
        --     complete_function_calls = true,
        --     vtsls = {
        --       enableMoveToFileCodeAction = true,
        --       autoUseWorkspaceTsdk = true,
        --       experimental = {
        --         completion = {
        --           enableServerSideFuzzyMatch = true,
        --         },
        --       },
        --     },
        --     typescript = {
        --       updateImportsOnFileMove = { enabled = "always" },
        --       suggest = {
        --         completeFunctionCalls = true,
        --       },
        --       inlayHints = {
        --         enumMemberValues = { enabled = true },
        --         functionLikeReturnTypes = { enabled = true },
        --         parameterNames = { enabled = "literals" },
        --         parameterTypes = { enabled = true },
        --         propertyDeclarationTypes = { enabled = true },
        --         variableTypes = { enabled = false },
        --       },
        --     },
        --   },
        -- },
      }

      require("mason").setup()

      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, { "stylua" })

      require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

      -- local capabilities = vim.tbl_deep_extend(
      --   "force",
      --   vim.lsp.protocol.make_client_capabilities(),
      --   require("cmp_nvim_lsp").default_capabilities()
      -- )

      -- server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
      require("mason-lspconfig").setup({
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            server.capabilities = vim.tbl_deep_extend(
              "force",
              vim.lsp.protocol.make_client_capabilities(),
              require("blink.cmp").get_lsp_capabilities()
            )
            require("lspconfig")[server_name].setup(server)
          end,
        },
      })
    end,
  },
}
