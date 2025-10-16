-- ========================================
-- Leader Keys
-- ========================================
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

-- Sync with system clipboard
-- Example: yy copies line to system clipboard, can paste in other apps
vim.o.clipboard = 'unnamedplus'

-- Persistent undo across sessions
-- Example: Close nvim, reopen file, press u to undo previous session's changes
vim.o.undofile = true
vim.o.undolevels = 10000

-- Disable backup/swap files (rely on undo history instead)
vim.o.backup = false
vim.o.swapfile = false

-- Prompt instead of failing when closing unsaved buffer
-- Example: :q on modified buffer asks "Save changes?" instead of error
vim.o.confirm = true

-- Faster CursorHold events and completion
-- Example: Diagnostics appear after 250ms instead of default 4000ms
vim.o.updatetime = 250

-- Auto-save when switching buffers or running commands
-- Example: :next automatically saves current buffer before switching
vim.o.autowrite = true

-- Allow cursor to go beyond line end in visual block mode
-- Example: <C-v> can select rectangle beyond line endings for alignment
vim.o.virtualedit = 'block'

-- ========================================
-- User Interface
-- ========================================
-- Line numbers: absolute on current, relative on others
-- Example: Current line shows "5", lines above/below show distance (1,2,3...)
vim.o.number = true
vim.o.relativenumber = true

-- Highlight the line where cursor is
-- Example: Current line has subtle background highlight
vim.o.cursorline = true

-- Always reserve space for signs (breakpoints, git, diagnostics)
-- Example: No text shift when git signs appear/disappear
vim.o.signcolumn = 'yes'

-- No vertical line at column 80 by default
vim.o.colorcolumn = ''

-- Enable 24-bit RGB colors (requires compatible terminal)
vim.o.termguicolors = true

-- Single global statusline at bottom (not per window)
vim.o.laststatus = 3

-- Hide command line when not typing commands
-- Example: More screen space, command line only appears when typing :
vim.o.cmdheight = 0

-- Don't show mode in command line (INSERT, VISUAL, etc)
-- Let statusline plugins handle this
vim.o.showmode = false
vim.o.showcmd = false
vim.o.ruler = false

-- Don't set terminal title
vim.o.title = false

-- Never show tab line
vim.o.showtabline = 0

-- Limit popup menu height and add transparency
-- Example: Autocomplete shows max 9 items, slightly transparent
vim.o.pumheight = 10
vim.o.pumblend = 10

-- ========================================
-- Search & Replace
-- ========================================
-- Case-insensitive search by default
-- Example: /hello matches "Hello", "HELLO", "hello"
vim.o.ignorecase = true

-- Override ignorecase if search has capitals
-- Example: /Hello only matches "Hello", not "hello"
vim.o.smartcase = true

-- Highlight all search matches
-- Example: /foo highlights all "foo" in buffer
vim.o.hlsearch = true

-- Show matches while typing search
-- Example: As you type /hel, jumps to first "hel" match
vim.o.incsearch = true

-- Live preview of substitutions in split window
-- Example: :%s/foo/bar shows changes before confirming
vim.o.inccommand = 'split'

-- Use ripgrep for :grep command
-- Example: :grep "TODO" finds all TODOs using ripgrep
vim.o.grepprg = 'rg --vimgrep'
vim.o.grepformat = '%f:%l:%c:%m'

-- ========================================
-- Indentation & Formatting
-- ========================================
-- Use spaces instead of tabs
-- Example: Pressing Tab inserts 2 spaces
vim.o.expandtab = true

-- Width of tab/indent
-- Example: Tab key inserts 2 spaces, >> indents by 2 spaces
vim.o.tabstop = 2
vim.o.shiftwidth = 2

-- Smart auto-indenting for new lines
-- Example: After {, next line is auto-indented
vim.o.smartindent = true

-- Wrapped lines continue at same indent
-- Example: Long indented line wraps with matching indent
vim.o.breakindent = true

-- Don't wrap long lines
-- Example: Long lines extend beyond window width
vim.o.wrap = false

-- ========================================
-- Scrolling & Windows
-- ========================================
-- Keep 5 lines visible above/below cursor
-- Example: Cursor never reaches very top/bottom of screen
vim.o.scrolloff = 5

-- Keep 5 columns visible left/right of cursor
-- Example: Horizontal scrolling keeps context
vim.o.sidescrolloff = 5

-- Smooth scrolling with <C-d>/<C-u>
vim.o.smoothscroll = true

-- New splits open in intuitive positions
-- Example: :split opens below, :vsplit opens to right
vim.o.splitbelow = true
vim.o.splitright = true

-- Keep same screen line when opening splits
-- Example: :split doesn't jump to different position
vim.o.splitkeep = 'screen'

-- Minimum window width when splitting
vim.o.winminwidth = 5

-- ========================================
-- Folding
-- ========================================
-- Enable code folding
vim.o.foldenable = true

-- Start with all folds open
-- Example: Opening file shows all code expanded
vim.o.foldlevelstart = 99

-- Use treesitter for smart folding (functions, classes, etc)
vim.o.foldmethod = 'expr'
vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

-- Default fold text display
vim.o.foldtext = ''

-- Don't show fold indicators in left column
vim.o.foldcolumn = '0'

-- ========================================
-- Special Characters & Display
-- ========================================
-- Show invisible characters
-- Example: Tabs appear as "» ", trailing spaces as "·"
vim.o.list = true
vim.o.listchars = 'tab:» ,trail:·,nbsp:␣,extends:→,precedes:←'

-- UI border/fill characters
-- Example: Empty lines show nothing (not ~), folds use custom icons
vim.o.fillchars = 'eob: ,fold: ,foldopen:▾,foldsep: ,foldclose:▸,diff:╱'

-- Don't hide text (markdown, json, etc)
-- Example: **bold** shows asterisks in markdown
vim.o.conceallevel = 0

-- Abbreviate messages to reduce "Press ENTER" prompts
-- Example: "W" instead of "written", no intro message
vim.o.shortmess = 'filnxtToOFWIcC'

-- ========================================
-- Other Settings
-- ========================================
-- Better jumplist behavior
-- Example: <C-o>/<C-i> navigate through jump history more intuitively
vim.o.jumpoptions = 'stack'

-- What to save in sessions
vim.o.sessionoptions = 'buffers,curdir,tabpages,winsize,help,globals,skiprtp,folds'

-- Time to wait for key sequence (ms)
-- Example: Pressing <leader> waits 300ms for next key
vim.o.timeoutlen = 300

-- Tab closing behavior
vim.o.tabclose = 'uselast'

-- Better completion menu behavior
-- Example: Always show menu, even for single match, don't auto-select
vim.o.completeopt = 'menu,menuone,noselect'

-- Command-line completion behavior
-- Example: Tab shows longest match, then full menu
vim.o.wildmode = 'longest:full,full'

-- Format options (see :h formatoptions)
-- j: Remove comment leader when joining lines
-- c: Auto-wrap comments
-- r: Continue comments on Enter
-- o: Continue comments with o/O
-- q: Format comments with gq
-- l: Don't break existing long lines
-- n: Recognize numbered lists
-- t: Auto-wrap text
vim.o.formatoptions = 'jcroqlnt'
vim.o.winborder = 'rounded'
