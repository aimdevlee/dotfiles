-- Smear Cursor Animation Configuration
return {
  "sphamba/smear-cursor.nvim",
  enabled = false,
  config = function()
    require("smear_cursor").setup({
      min_horizontal_distance_smear = 3,
      min_vertical_distance_smear = 3,
      stiffness = 0.6,
      trailing_stiffness = 0.4,
      trailing_exponent = 1.5,
      slowdown_exponent = -0.1,
      distance_stop_animating = 0.1,
    })
  end,
}