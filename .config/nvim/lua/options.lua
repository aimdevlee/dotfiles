local g = vim.g
local o = vim.o

-- ========================================
-- Leader Keys
-- ========================================
g.mapleader = " "
g.maplocalleader = "\\"

-- ========================================
-- Editor Behavior
-- ========================================
-- Enable mouse in all modes (normal, insert, visual, command)
-- Example: Click to position cursor, drag to select, scroll with wheel
o.mouse = "a"

-- Sync with system clipboard
-- Example: yy copies line to system clipboard, can paste in other apps
o.clipboard = "unnamedplus"

-- Persistent undo across sessions
-- Example: Close nvim, reopen file, press u to undo previous session's changes
o.undofile = true
o.undolevels = 10000

-- Disable backup/swap files (rely on undo history instead)
o.backup = false
o.swapfile = false

-- Prompt instead of failing when closing unsaved buffer
-- Example: :q on modified buffer asks "Save changes?" instead of error
o.confirm = true

-- Faster CursorHold events and completion
-- Example: Diagnostics appear after 250ms instead of default 4000ms
o.updatetime = 250

-- Auto-save when switching buffers or running commands
-- Example: :next automatically saves current buffer before switching
o.autowrite = true

-- Allow cursor to go beyond line end in visual block mode
-- Example: <C-v> can select rectangle beyond line endings for alignment
o.virtualedit = "block"

-- ========================================
-- User Interface
-- ========================================
-- Line numbers: absolute on current, relative on others
-- Example: Current line shows "5", lines above/below show distance (1,2,3...)
o.number = true
o.relativenumber = true

-- Highlight the line where cursor is
-- Example: Current line has subtle background highlight
o.cursorline = true

-- Always reserve space for signs (breakpoints, git, diagnostics)
-- Example: No text shift when git signs appear/disappear
o.signcolumn = "yes"

-- No vertical line at column 80 by default
o.colorcolumn = ""

-- Enable 24-bit RGB colors (requires compatible terminal)
o.termguicolors = true

-- Single global statusline at bottom (not per window)
o.laststatus = 3

-- Hide command line when not typing commands
-- Example: More screen space, command line only appears when typing :
o.cmdheight = 0

-- Don't show mode in command line (INSERT, VISUAL, etc)
-- Let statusline plugins handle this
o.showmode = false
o.showcmd = false
o.ruler = false

-- Don't set terminal title
o.title = false

-- Never show tab line
o.showtabline = 0

-- Limit popup menu height and add transparency
-- Example: Autocomplete shows max 10 items, slightly transparent
o.pumheight = 10
o.pumblend = 10

-- ========================================
-- Search & Replace
-- ========================================
-- Case-insensitive search by default
-- Example: /hello matches "Hello", "HELLO", "hello"
o.ignorecase = true

-- Override ignorecase if search has capitals
-- Example: /Hello only matches "Hello", not "hello"
o.smartcase = true

-- Highlight all search matches
-- Example: /foo highlights all "foo" in buffer
o.hlsearch = true

-- Show matches while typing search
-- Example: As you type /hel, jumps to first "hel" match
o.incsearch = true

-- Live preview of substitutions in split window
-- Example: :%s/foo/bar shows changes before confirming
o.inccommand = "split"

-- Use ripgrep for :grep command
-- Example: :grep "TODO" finds all TODOs using ripgrep
o.grepprg = "rg --vimgrep"
o.grepformat = "%f:%l:%c:%m"

-- ========================================
-- Indentation & Formatting
-- ========================================
-- Use spaces instead of tabs
-- Example: Pressing Tab inserts 2 spaces
o.expandtab = true

-- Width of tab/indent
-- Example: Tab key inserts 2 spaces, >> indents by 2 spaces
o.tabstop = 2
o.shiftwidth = 2

-- Smart auto-indenting for new lines
-- Example: After {, next line is auto-indented
o.smartindent = true

-- Wrapped lines continue at same indent
-- Example: Long indented line wraps with matching indent
o.breakindent = true

-- Don't wrap long lines
-- Example: Long lines extend beyond window width
o.wrap = false

-- ========================================
-- Scrolling & Windows
-- ========================================
-- Keep 5 lines visible above/below cursor
-- Example: Cursor never reaches very top/bottom of screen
o.scrolloff = 5

-- Keep 5 columns visible left/right of cursor
-- Example: Horizontal scrolling keeps context
o.sidescrolloff = 5

-- Smooth scrolling with <C-d>/<C-u>
o.smoothscroll = true

-- New splits open in intuitive positions
-- Example: :split opens below, :vsplit opens to right
o.splitbelow = true
o.splitright = true

-- Keep same screen line when opening splits
-- Example: :split doesn't jump to different position
o.splitkeep = "screen"

-- Minimum window width when splitting
o.winminwidth = 5

-- ========================================
-- Folding
-- ========================================
-- Enable code folding
o.foldenable = true

-- Start with all folds open
-- Example: Opening file shows all code expanded
o.foldlevelstart = 99

-- Use treesitter for smart folding (functions, classes, etc)
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"

-- Default fold text display
o.foldtext = ""

-- Don't show fold indicators in left column
o.foldcolumn = "0"

-- ========================================
-- Special Characters & Display
-- ========================================
-- Show invisible characters
-- Example: Tabs appear as "» ", trailing spaces as "·"
o.list = true
o.listchars = "tab:» ,trail:·,nbsp:␣,extends:→,precedes:←"

-- UI border/fill characters
-- Example: Empty lines show nothing (not ~), folds use custom icons
o.fillchars = "eob: ,fold: ,foldopen:▾,foldsep: ,foldclose:▸,diff:╱"

-- Don't hide text (markdown, json, etc)
-- Example: **bold** shows asterisks in markdown
o.conceallevel = 0

-- Abbreviate messages to reduce "Press ENTER" prompts
-- Example: "W" instead of "written", no intro message
o.shortmess = "filnxtToOFWIcC"

-- ========================================
-- Other Settings
-- ========================================
-- Better jumplist behavior
-- Example: <C-o>/<C-i> navigate through jump history more intuitively
o.jumpoptions = "stack"

-- What to save in sessions
o.sessionoptions = "buffers,curdir,tabpages,winsize,help,globals,skiprtp,folds"

-- Time to wait for key sequence (ms)
-- Example: Pressing <leader> waits 300ms for next key
o.timeoutlen = 300

-- Tab closing behavior
o.tabclose = "uselast"

-- Better completion menu behavior
-- Example: Always show menu, even for single match, don't auto-select
o.completeopt = "menu,menuone,noselect"

-- Command-line completion behavior
-- Example: Tab shows longest match, then full menu
o.wildmode = "longest:full,full"

-- Format options (see :h formatoptions)
-- j: Remove comment leader when joining lines
-- c: Auto-wrap comments
-- r: Continue comments on Enter
-- o: Continue comments with o/O
-- q: Format comments with gq
-- l: Don't break existing long lines
-- n: Recognize numbered lists
-- t: Auto-wrap text
o.formatoptions = "jcroqlnt"

