local wezterm = require("wezterm")
local action = wezterm.action
local config = wezterm.config_builder()

local function is_vim(pane)
	local process_info = pane:get_foreground_process_info()
	local process_name = process_info and process_info.name

	return process_name == "nvim" or process_name == "vim"
end

local direction_keys = {
	Left = "h",
	Down = "j",
	Up = "k",
	Right = "l",
	-- reverse lookup
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

local function split_nav(resize_or_move, key)
	return {
		key = key,
		mods = resize_or_move == "resize" and "META" or "CTRL",
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				-- pass the keys through to vim/nvim
				win:perform_action({
					SendKey = { key = key, mods = resize_or_move == "resize" and "META" or "CTRL" },
				}, pane)
			else
				if resize_or_move == "resize" then
					win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
				else
					win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
				end
			end
		end),
	}
end

--  appearance
config.color_scheme = "Tokyo Night"
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.9
config.macos_window_background_blur = 20
config.enable_tab_bar = false

-- default cwd
config.default_cwd = "~/works"

-- font
config.font = wezterm.font({ family = "D2Coding Ligature" })
config.font_size = 13

config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
	-- splitting
	{
		mods = "LEADER",
		key = "-",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		mods = "LEADER",
		key = "|",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		mods = "LEADER",
		key = "m",
		action = wezterm.action.TogglePaneZoomState,
	},
	{
		mods = "LEADER",
		key = "Space",
		action = wezterm.action.RotatePanes("Clockwise"),
	},
	{
		mods = "LEADER",
		key = "Enter",
		action = wezterm.action.ActivateCopyMode,
	},
	{
		mods = "LEADER",
		key = "0",
		action = action.PaneSelect({
			mode = "SwapWithActive",
			alphabet = "1234567890",
		}),
	},
	{
		mods = "LEADER",
		key = "p",
		action = action.PaneSelect({
			alphabet = "1234567890",
		}),
	},
	{
		key = "x",
		mods = "LEADER",
		action = action.CloseCurrentPane({ confirm = true }),
	},
	-- move between split panes
	split_nav("move", "h"),
	split_nav("move", "j"),
	split_nav("move", "k"),
	split_nav("move", "l"),
	-- resize panes
	split_nav("resize", "h"),
	split_nav("resize", "j"),
	split_nav("resize", "k"),
	split_nav("resize", "l"),
	-- Rebind OPT-Left, OPT-Right as ALT-b, ALT-f respectively to match Terminal.app behavior
	{
		key = "LeftArrow",
		mods = "OPT",
		action = action.SendKey({
			key = "b",
			mods = "ALT",
		}),
	},
	{
		key = "RightArrow",
		mods = "OPT",
		action = action.SendKey({ key = "f", mods = "ALT" }),
	},
}

return config
