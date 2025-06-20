-- Harpoon File Navigation Configuration
return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  config = function()
    local harpoon = require("harpoon")
    -- stylua: ignore start
    vim.keymap.set("n", "<leader>ha", function() harpoon:list():add() end, { desc = "Add" })
    vim.keymap.set("n", "<leader>hl", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "List" })
    -- Toggle previous & next buffers stored within Harpoon list
    vim.keymap.set("n", "<leader>hp", function() harpoon:list():prev() end, { desc = "Prev" })
    vim.keymap.set("n", "<leader>hn", function() harpoon:list():next() end, { desc = "Next" })
    -- stylua: ignore end
  end,
}