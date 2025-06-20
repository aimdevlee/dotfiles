-- Render Markdown Configuration
return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown", "codecompanion" },
  config = function()
    require("render-markdown").setup({
      completions = { blink = { enabled = true } },
      win_options = {
        conceallevel = { rendered = 2 },
      },
      heading = {
        enabled = false,
        position = "inline",
        atx = false,
      },
    })
  end,
}