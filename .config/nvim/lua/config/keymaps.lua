-- mode prefix
-- n Normal mode
-- i Insert mode
-- v Visual mode
-- x Visual mode
-- s Select mode
-- o Operator-pending mode
-- t Terminal mode
-- c Command-line mode

if vim.g.vscode == 1 then
else
  -- better up/down
  vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
  vim.keymap.set({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
  vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
  vim.keymap.set({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

  -- Move to window using the <ctrl> hjkl keys
  vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
  vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
  vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
  vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

  -- Move Lines
  vim.keymap.set("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move Down" })
  vim.keymap.set("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move Up" })
  vim.keymap.set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
  vim.keymap.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
  vim.keymap.set("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
  vim.keymap.set("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move Up" })

  -- buffers
  vim.keymap.set("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
  vim.keymap.set("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
  vim.keymap.set("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
  vim.keymap.set("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })

  -- Clear search with <esc>
  vim.keymap.set({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and Clear hlsearch" })

  -- Clear search, diff update and redraw
  -- taken from runtime/lua/_editor.lua
  vim.keymap.set(
    "n",
    "<leader>ur",
    "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
    { desc = "Redraw / Clear hlsearch / Diff Update" }
  )

  -- yank current file path
  vim.keymap.set("n", "<leader>yp", ":let @*=expand('%:p')<cr>", { desc = "Yank current file path" })
  -- yank current file name
  vim.keymap.set("n", "<leader>yn", ":let @*=expand('%:t')<cr>", { desc = "Yank current file name" })

  -- save file
  vim.keymap.set({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

  -- better indenting
  vim.keymap.set("v", "<", "<gv")
  vim.keymap.set("v", ">", ">gv")

  -- commenting
  vim.keymap.set("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
  vim.keymap.set("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

  -- lazy
  vim.keymap.set("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })

  -- new file
  vim.keymap.set("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

  vim.keymap.set("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
  vim.keymap.set("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix List" })

  vim.keymap.set("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
  vim.keymap.set("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

  -- diagnostic
  local diagnostic_goto = function(next, severity)
    local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
    severity = severity and vim.diagnostic.severity[severity] or nil
    return function()
      go({ severity = severity })
    end
  end

  vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
  vim.keymap.set("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
  vim.keymap.set("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
  vim.keymap.set("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
  vim.keymap.set("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
  vim.keymap.set("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
  vim.keymap.set("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

  -- quit
  vim.keymap.set("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })

  -- Terminal Mappings
  vim.keymap.set("t", "<C-h>", "<cmd>wincmd h<cr>", { desc = "Go to Left Window" })
  vim.keymap.set("t", "<C-j>", "<cmd>wincmd j<cr>", { desc = "Go to Lower Window" })
  vim.keymap.set("t", "<C-k>", "<cmd>wincmd k<cr>", { desc = "Go to Upper Window" })
  vim.keymap.set("t", "<C-l>", "<cmd>wincmd l<cr>", { desc = "Go to Right Window" })

  -- windows
  vim.keymap.set("n", "<leader>w", "<c-w>", { desc = "Windows", remap = true })
  vim.keymap.set("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
  vim.keymap.set("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
  vim.keymap.set("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })

  -- tabs
  vim.keymap.set("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
  vim.keymap.set("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
  vim.keymap.set("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
  vim.keymap.set("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
  vim.keymap.set("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
  vim.keymap.set("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
  vim.keymap.set("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

  vim.keymap.set("i", "<M-h>", "<BS>", {})
end
