local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.enable_tab_bar = false

config.font_size = 13.0

config.window_decorations = "RESIZE"

config.color_scheme = "Catppuccin Macchiato"

return config
