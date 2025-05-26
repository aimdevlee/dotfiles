return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        panel = {
          enabled = true,
          layout = {
            position = "right",
          },
        },
        suggestion = { enabled = true, auto_trigger = true, hide_during_completion = true },
        copilot_model = "gpt-4o-copilot",
      })
    end,
  },
  {
    "olimorris/codecompanion.nvim",
    config = function()
      require("codecompanion").setup({
        strategies = {
          chat = {
            adapter = "copilot",
          },
          inline = {
            adapter = "copilot",
          },
        },
        adapters = {
          copilot = function()
            return require("codecompanion.adapters").extend("copilot", {
              schema = {
                model = {
                  default = "claude-3.7-sonnet",
                },
              },
            })
          end,
        },
        opts = {
          language = "Korean",
          send_code = false,
        },
        display = {
          action_palette = {
            provider = "snacks",
          },
          chat = {
            auto_scroll = false,
            show_header_separator = true,
          },
        },
      })
    end,
  },
}
