-- Leap Motion Configuration
return {
  "ggandor/leap.nvim",
  config = function()
    local leap = require("leap")
    leap.set_default_mappings()
    leap.opts.case_sensitive = true
    vim.api.nvim_set_hl(0, "LeapBackdrop", { link = "Comment" })
    vim.keymap.set({ "n", "x", "o" }, "gs", function()
      require("leap.remote").action()
    end)
  end,
}