-- GitHub Copilot Configuration
return {
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
      suggestion = { 
        enabled = true, 
        auto_trigger = true, 
        hide_during_completion = true 
      },
      copilot_model = "gpt-4o-copilot",
    })
  end,
}