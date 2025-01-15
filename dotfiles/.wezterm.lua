-- Pull in the wezterm API
local wezterm = require("wezterm")
local mux = wezterm.mux

-- Start wezterm maximized
wezterm.on("gui-startup", function()
	local tab, pane, window = mux.spawn_window({})
	window:gui_window():maximize()
end)

-- Wezterm action for configuring keybindings
local act = wezterm.action
-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

config = {
	--term = "wezterm",

	default_gui_startup_args = { "start" },

	enable_wayland = true,

	default_cwd = "~/",

	-- Fix Wezterm crash after sleep
	front_end = "OpenGL",

	-- Enable kitty graphics protocol (Buggy)
	enable_kitty_graphics = true,

	--prompt_order = { "CurrentDir", "GitBranch" },

	max_fps = 165,

	hide_tab_bar_if_only_one_tab = false,

	-- F11 for Fullscreen
	keys = {
		{
			key = "F11",
			mods = "NONE",
			action = wezterm.action.ToggleFullScreen,
		},
		-- disable default new window spawn
		{
			key = "Enter",
			mods = "ALT",
			action = wezterm.action.DisableDefaultAssignment,
		},
	},

	-- Disable middle click pastes
	mouse_bindings = {
		{
			event = { Down = { streak = 1, button = "Middle" } },
			mods = "NONE",
			action = act.Nop,
		},

		-- NOTE that binding only the 'Up' event can give unexpected behaviors.
		-- Read more below on the gotcha of binding an 'Up' event only.
	},

	--#######################
	--#### FONT SETTINGS ####
	--#######################

	-- Disable ligatures
	harfbuzz_features = { "calt=0", "clig=0", "liga=0" },

	-- Font Settings
	font = wezterm.font_with_fallback({
		-- "MonaspiceNe Nerd Font Mono Light",
		{ family = "MonaspiceNe Nerd Font Mono", weight = "Light", stretch = "Normal", style = "Normal" },
		-- "Nerd Font Symbols",
		"Noto Color Emoji",
	}),

	font_size = 14.0,

	--#######################
	--#### COLOR SETTINGS ###
	--#######################

	-- For example, changing the color scheme:
	-- color_scheme = "Tokyo Night"
	--color_scheme = "Bright (base16)"
	-- color_scheme = "Brogrammer"
	-- color_scheme = "Builtin Dark"
	-- color_scheme = "Borland (Gogh)"
	-- color_scheme = "Breeze"
	color_scheme = "Breeze (Gogh)",

	colors = {
		foreground = "#d1d4dc",
		background = "#000050",
		cursor_bg = "#d1d4dc",
		cursor_fg = "black",
	},
}
--##########################
--#### ADVANCED SETTINGS ###
--##########################

-- Nvim Zen Mode Integration
wezterm.on("user-var-changed", function(window, pane, name, value)
	local overrides = window:get_config_overrides() or {}
	if name == "ZEN_MODE" then
		local incremental = value:find("+")
		local number_value = tonumber(value)
		if incremental ~= nil then
			while number_value > 0 do
				window:perform_action(wezterm.action.IncreaseFontSize, pane)
				number_value = number_value - 1
			end
			overrides.enable_tab_bar = false
		elseif number_value < 0 then
			window:perform_action(wezterm.action.ResetFontSize, pane)
			overrides.font_size = nil
			overrides.enable_tab_bar = true
		else
			overrides.font_size = number_value
			overrides.enable_tab_bar = false
		end
	end
	window:set_config_overrides(overrides)
end)

-- Background Opacity Options
-- Acrylic
-- config.window_background_opacity = 0
-- config.win32_system_backdrop = 'Acrylic'
-- Mica
-- Tabbed
-- config.window_background_opacity = 0
-- config.win32_system_backdrop = 'Tabbed'

-- Background Image Options
--local dimmer = { brightness = 0.05 }

-- config.background = {
--
-- 	{
-- 		source = {
-- 			File = "/home/jordan/.terminal-backgrounds/Bath.png",
-- 		},
-- 		hsb = dimmer,
-- 	},
-- }

--#######################
--#### TAB SETTINGS #####
--#######################

-- config.colors = {
-- 	-- The default text color
-- 	foreground = "silver",
-- 	-- The default background color
-- 	background = "black",
--
-- 	-- Overrides the cell background color when the current cell is occupied by the
-- 	-- cursor and the cursor style is set to Block
-- 	cursor_bg = "silver",
-- 	-- Overrides the text color when the current cell is occupied by the cursor
-- 	cursor_fg = "black",
-- 	-- Specifies the border color of the cursor when the cursor style is set to Block,
-- 	-- or the color of the vertical or horizontal bar when the cursor style is set to
-- 	-- Bar or Underline.
-- 	cursor_border = "#52ad70",
--
-- 	-- the foreground color of selected text
-- 	selection_fg = "black",
-- 	-- the background color of selected text
-- 	selection_bg = "#fffacd",
--
-- 	-- The color of the scrollbar "thumb"; the portion that represents the current viewport
-- 	scrollbar_thumb = "#222222",
--
-- 	-- The color of the split lines between panes
-- 	split = "#444444",
--
-- 	ansi = {
-- 		"black",
-- 		"maroon",
-- 		"green",
-- 		"olive",
-- 		"navy",
-- 		"purple",
-- 		"teal",
-- 		"silver",
-- 	},
-- 	brights = {
-- 		"grey",
-- 		"red",
-- 		"lime",
-- 		"yellow",
-- 		"blue",
-- 		"fuchsia",
-- 		"aqua",
-- 		"white",
-- 	},
--
-- 	-- Arbitrary colors of the palette in the range from 16 to 255
-- 	indexed = { [136] = "#af8700" },
--
-- 	-- Since: 20220319-142410-0fcdea07
-- 	-- When the IME, a dead key or a leader key are being processed and are effectively
-- 	-- holding input pending the result of input composition, change the cursor
-- 	-- to this color to give a visual cue about the compose state.
-- 	compose_cursor = "orange",
--
-- 	-- Colors for copy_mode and quick_select
-- 	-- available since: 20220807-113146-c2fee766
-- 	-- In copy_mode, the color of the active text is:
-- 	-- 1. copy_mode_active_highlight_* if additional text was selected using the mouse
-- 	-- 2. selection_* otherwise
-- 	copy_mode_active_highlight_bg = { Color = "#000000" },
-- 	-- use `AnsiColor` to specify one of the ansi color palette values
-- 	-- (index 0-15) using one of the names "Black", "Maroon", "Green",
-- 	--  "Olive", "Navy", "Purple", "Teal", "Silver", "Grey", "Red", "Lime",
-- 	-- "Yellow", "Blue", "Fuchsia", "Aqua" or "White".
-- 	copy_mode_active_highlight_fg = { AnsiColor = "Black" },
-- 	copy_mode_inactive_highlight_bg = { Color = "#52ad70" },
-- 	copy_mode_inactive_highlight_fg = { AnsiColor = "White" },
--
-- 	quick_select_label_bg = { Color = "peru" },
-- 	quick_select_label_fg = { Color = "#ffffff" },
-- 	quick_select_match_bg = { AnsiColor = "Navy" },
-- 	quick_select_match_fg = { Color = "#ffffff" },
-- }

--[[
-- This is Wez's example config for the parallax scrolling background
--
-- The art is a bit too bright and colorful to be useful as a backdrop
-- for text, so we're going to dim it down to 10% of its normal brightness
local dimmer = { brightness = 0.1 }

config.enable_scroll_bar = true
config.min_scroll_bar_height = "2cell"
config.colors = {
	scrollbar_thumb = "white",
}

config.background = {
	-- This is the deepest/back-most layer. It will be rendered first
	{
		source = {
			File = "C:\\Users\\jvaan\\Programs\\Wallpapers\\Parallax\\Alien_Ship_bg_vert_images\\Backgrounds\\spaceship_bg_1.png",
		},
		-- The texture tiles vertically but not horizontally.
		-- When we repeat it, mirror it so that it appears "more seamless".
		-- An alternative to this is to set `width = "100%"` and have
		-- it stretch across the display
		repeat_x = "Mirror",
		hsb = dimmer,
		-- When the viewport scrolls, move this layer 10% of the number of
		-- pixels moved by the main viewport. This makes it appear to be
		-- further behind the text.
		attachment = { Parallax = 0.1 },
	},
	-- Subsequent layers are rendered over the top of each other
	{
		source = {
			File = "C:\\Users\\jvaan\\Programs\\Wallpapers\\Parallax\\Alien_Ship_bg_vert_images\\Overlays\\overlay_1_spines.png",
		},
		width = "100%",
		repeat_x = "NoRepeat",

		-- position the spins starting at the bottom, and repeating every
		-- two screens.
		vertical_align = "Bottom",
		repeat_y_size = "200%",
		hsb = dimmer,

		-- The parallax factor is higher than the background layer, so this
		-- one will appear to be closer when we scroll
		attachment = { Parallax = 0.2 },
	},
	{
		source = {
			File = "C:\\Users\\jvaan\\Programs\\Wallpapers\\Parallax\\Alien_Ship_bg_vert_images\\Overlays\\overlay_2_alienball.png",
		},
		width = "100%",
		repeat_x = "NoRepeat",

		-- start at 10% of the screen and repeat every 2 screens
		vertical_offset = "10%",
		repeat_y_size = "200%",
		hsb = dimmer,
		attachment = { Parallax = 0.3 },
	},
	{
		source = {
			File = "C:\\Users\\jvaan\\Programs\\Wallpapers\\Parallax\\Alien_Ship_bg_vert_images\\Overlays\\soverlay_3_lobster.png",
		},
		width = "100%",
		repeat_x = "NoRepeat",

		vertical_offset = "30%",
		repeat_y_size = "200%",
		hsb = dimmer,
		attachment = { Parallax = 0.4 },
	},
	{
		source = {
			File = "C:\\Users\\jvaan\\Programs\\Wallpapers\\Parallax\\Alien_Ship_bg_vert_images\\Overlays\\overlay_4_spiderlegs.png",
		},
		width = "100%",
		repeat_x = "NoRepeat",

		vertical_offset = "50%",
		repeat_y_size = "150%",
		hsb = dimmer,
		attachment = { Parallax = 0.5 },
	},
}
 ]]

-- and finally, return the configuration to wezterm
return config
