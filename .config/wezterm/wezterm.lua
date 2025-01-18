local wezterm = require("wezterm")
local action = wezterm.action
local config = {}

config = {
  --  appearance
  color_scheme = "catppuccin-frappe",
  colors = { compose_cursor = "red" },
  font = wezterm.font_with_fallback({
    { family = "Cica" },
    { family = "FiraCode Nerd Font", assume_emoji_presentation = true },
  }),
  font_size = 18,
  hide_tab_bar_if_only_one_tab = true,
  keys = {
    -- turn off default action
    { mods = "CMD", key = "m", action = action.DisableDefaultAssignment },
    { mods = "CMD", key = "h", action = action.DisableDefaultAssignment },
    -- maximize pane
    { mods = "CMD|SHIFT", key = "m", action = action.TogglePaneZoomState },
    -- splitting
    { mods = "CMD|SHIFT", key = "-", action = action.SplitVertical({ domain = "CurrentPaneDomain" }) },
    { mods = "CMD|SHIFT", key = "|", action = action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { mods = "CMD|SHIFT", key = "w", action = action.CloseCurrentPane({ confirm = true }) },
    -- navigate panes
    { mods = "CMD|SHIFT", key = "h", action = action.ActivatePaneDirection("Left") },
    { mods = "CMD|SHIFT", key = "j", action = action.ActivatePaneDirection("Down") },
    { mods = "CMD|SHIFT", key = "k", action = action.ActivatePaneDirection("Up") },
    { mods = "CMD|SHIFT", key = "l", action = action.ActivatePaneDirection("Right") },
    -- Rebind OPT-Left, OPT-Right as ALT-b, ALT-f respectively to match Terminal.app behavior
    { mods = "OPT", key = "LeftArrow", action = action.SendKey({ key = "b", mods = "ALT" }) },
    { mods = "OPT", key = "RightArrow", action = action.SendKey({ key = "f", mods = "ALT" }) },
  },
  macos_window_background_blur = 40,
  max_fps = 120,
  prefer_egl = true,
  tab_max_width = 20,
  underline_position = -5,
  use_fancy_tab_bar = false,
  window_decorations = "RESIZE",
  window_background_opacity = 0.85,
  window_close_confirmation = "NeverPrompt",
}

return config
