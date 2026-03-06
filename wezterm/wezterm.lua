-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()

local appearance = require("appearance")

if appearance.is_dark() then
	config.color_scheme = "Tokyo Night"
else
	config.color_scheme = "Tokyo Night Day"
end

wezterm.on("gui-startup", function()
	local tab, pane, window = wezterm.mux.spawn_window({})
	window:gui_window():maximize()
end)

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.debug_key_events = true
-- config.default_cwd = "/some/path"
-- config.font_dirs = { '/confifg/fonts' }
-- config.font = wezterm.font 'Iosevka'
-- config.font = wezterm.font({ family = "Berkeley Mono" })
config.font_size = 13

-- font = wezterm.font(family = 'Iosevka Term', { stretch = 'Expanded', weight = 'Regular })

-- Slightly transparent and blurred background
config.window_background_opacity = 0.9
config.macos_window_background_blur = 30
-- Removes the title bar, leaving only the tab bar. Keeps
-- the ability to resize by dragging the window's edges.
-- On macOS, 'RESIZE|INTEGRATED_BUTTONS' also looks nice if
-- you want to keep the window controls visible and integrate
-- them into the tab bar.
config.window_decorations = "RESIZE"
-- Sets the font for the window frame (tab bar)
config.window_frame = {
	-- Berkeley Mono for me again, though an idea could be to try a
	-- serif font here instead of monospace for a nicer look?
	-- font = wezterm.font({ family = "Berkeley Mono" }),
	font_size = 11,
}

-- always search case insensitive
-- config.search_case_sensitive = false

local function segments_for_right_status(window)
	return {
		window:active_workspace(),
		wezterm.strftime("%a %b %-d %H:%M"),
		wezterm.hostname(),
	}
end

-- powerline-ish status bar
wezterm.on("update-status", function(window, _)
	local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
	local segments = segments_for_right_status(window)

	local color_scheme = window:effective_config().resolved_palette
	-- Note the use of wezterm.color.parse here, this returns
	-- a Color object, which comes with functionality for lightening
	-- or darkening the colour (amongst other things).
	local bg = wezterm.color.parse(color_scheme.background)
	local fg = color_scheme.foreground

	-- Each powerline segment is going to be coloured progressively
	-- darker/lighter depending on whether we're on a dark/light colour
	-- scheme. Let's establish the "from" and "to" bounds of our gradient.
	local gradient_to, gradient_from = bg
	if appearance.is_dark() then
		gradient_from = gradient_to:lighten(0.2)
	else
		gradient_from = gradient_to:darken(0.2)
	end

	-- Yes, WezTerm supports creating gradients, because why not?! Although
	-- they'd usually be used for setting high fidelity gradients on your terminal's
	-- background, we'll use them here to give us a sample of the powerline segment
	-- colours we need.
	local gradient = wezterm.color.gradient(
		{
			orientation = "Horizontal",
			colors = { gradient_from, gradient_to },
		},
		#segments -- only gives us as many colours as we have segments.
	)

	-- We'll build up the elements to send to wezterm.format in this table.
	local elements = {}

	for i, seg in ipairs(segments) do
		local is_first = i == 1

		if is_first then
			table.insert(elements, { Background = { Color = "none" } })
		end
		table.insert(elements, { Foreground = { Color = gradient[i] } })
		table.insert(elements, { Text = SOLID_LEFT_ARROW })

		table.insert(elements, { Foreground = { Color = fg } })
		table.insert(elements, { Background = { Color = gradient[i] } })
		table.insert(elements, { Text = " " .. seg .. " " })
	end

	window:set_right_status(wezterm.format(elements))
end)

-- https://github.com/wez/wezterm/issues/3731
-- Command key in macOS neovim
--
local function is_vim(pane)
	local is_vim_env = pane:get_user_vars().IS_NVIM == "true"

	if is_vim_env == true then
		return true
	end
	-- This gsub is equivalent to POSIX basename(3)
	-- Given "/foo/bar" returns "bar"
	-- Given "c:\\foo\\bar" returns "bar"
	local process_name = string.gsub(pane:get_foreground_process_name(), "(.*[/\\])(.*)", "%2")
	return process_name == "nvim" or process_name == "vim"
end

--- cmd+keys that we want to send to neovim.
local super_vim_keys_map = {
	s = utf8.char(0xAA),
	x = utf8.char(0xAB),
	b = utf8.char(0xAC),
	["."] = utf8.char(0xAD),
	o = utf8.char(0xAF),
}

local function bind_super_key_to_vim(key)
	return {
		key = key,
		mods = "CMD",
		action = wezterm.action_callback(function(win, pane)
			local char = super_vim_keys_map[key]
			if char and is_vim(pane) then
				-- pass the keys through to vim/nvim
				win:perform_action({
					SendKey = { key = char, mods = nil },
				}, pane)
			else
				win:perform_action({
					SendKey = {
						key = key,
						mods = "CMD",
					},
				}, pane)
			end
		end),
	}
end

config.set_environment_variables = {
	-- This changes the default prompt for cmd.exe to report the
	-- current directory using OSC 7, show the current time and
	-- the current directory colored in the prompt.
	prompt = "$E]7;file://localhost/$P$E\\$E[32m$T$E[0m $E[35m$P$E[36m$_$G$E[0m ",
}

-- wezterm-move
-- https://github.com/letieu/wezterm-move.nvim

config.leader = {
	key = "Space",
	mods = "CTRL",
	timeout_milliseconds = math.maxinteger,
}

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

-- Table mapping keypresses to actions
config.keys = {
	bind_super_key_to_vim("s"),
	-- claude & codex don't like shift + enter with wezterm. this uses kitty keyboard protocol excape sequence
	{ key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\x1b[13;2u") },
	{
		key = "\\",
		mods = "CMD",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "\\",
		mods = "CMD|SHIFT",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "w",
		mods = "SUPER",
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},
	{
		key = "k",
		mods = "CMD",
		action = wezterm.action.ClearScrollback("ScrollbackAndViewport"),
	},

	-- scroll navigation
	{ key = "u", mods = "CTRL", action = act.ScrollByPage(-0.5) },
	{ key = "d", mods = "CTRL", action = act.ScrollByPage(0.5) },
	{ key = "PageUp", action = act.ScrollByPage(-1) },
	{ key = "PageDown", action = act.ScrollByPage(1) },
	-- natural text cursor editing:
	{ mods = "OPT", key = "LeftArrow", action = wezterm.action.SendKey({ mods = "ALT", key = "b" }) },
	{ mods = "OPT", key = "RightArrow", action = wezterm.action.SendKey({ mods = "ALT", key = "f" }) },
	{ mods = "CMD", key = "LeftArrow", action = wezterm.action.SendKey({ mods = "CTRL", key = "a" }) },
	{ mods = "CMD", key = "RightArrow", action = wezterm.action.SendKey({ mods = "CTRL", key = "e" }) },
	{ mods = "CMD", key = "Backspace", action = wezterm.action.SendKey({ mods = "CTRL", key = "u" }) },

	-- make all search case insensitive
	{
		key = "f",
		mods = "CMD",
		action = wezterm.action.Search({ CaseInSensitiveString = "" }),
	},
	{
		key = "F",
		mods = "CMD",
		action = wezterm.action.Search({ CaseSensitiveString = "" }),
	},

	-- use ijkl for arrows
	{
		key = "l",
		mods = "CTRL",
		action = wezterm.action.SendKey({ key = "RightArrow" }),
	},

	{
		key = "j",
		mods = "CTRL",
		action = wezterm.action.SendKey({ key = "LeftArrow" }),
	},
	{
		key = "i",
		mods = "CTRL",
		action = wezterm.action.SendKey({ key = "UpArrow" }),
	},
	{
		key = "k",
		mods = "CTRL",
		action = wezterm.action.SendKey({ key = "DownArrow" }),
	},

	-- Activate Launcher Menu
	{
		key = "l",
		mods = "CMD",
		action = wezterm.action.ShowLauncher,
	},

	-- Activate copy mode
	{
		key = "c",
		mods = "LEADER",
		action = wezterm.action.ActivateCopyMode,
	},

	-- { key = "LeftArrow", mods = "OPT|SHIFT", action = wezterm.action.ActivateCopyMode },
	-- { key = "RightArrow", mods = "OPT|SHIFT", action = wezterm.action.ActivateCopyMode },
	-- { key = "LeftArrow", mods = "CMD|SHIFT", action = wezterm.action.ActivateCopyMode },
	-- { key = "RightArrow", mods = "CMD|SHIFT", action = wezterm.action.ActivateCopyMode },
	--
	-- { key = "LeftArrow", mods = "OPT|SHIFT", action = wezterm.action.CopyMode("MoveBackwardWord") },
	-- { key = "LeftArrow", mods = "OPT|SHIFT", action = wezterm.action.CopyMode({ SetSelectionMode = "Word" }) },
	-- -- { key = "LeftArrow", mods = "OPT|SHIFT", action = wezterm.action.CopyMode("ToggleSel") },
	-- { key = "RightArrow", mods = "OPT|SHIFT", action = wezterm.action.CopyMode("MoveForwardWordEnd") },
	-- { key = "RightArrow", mods = "OPT|SHIFT", action = wezterm.action.CopyMode({ SetSelectionMode = "Word" }) },
	-- { key = "RightArrow", mods = "OPT|SHIFT", action = wezterm.action.CopyMode("ToggleSel") },

	-- { mods = "CMD|SHIFT", key = "LeftArrow", action = wezterm.action.SendKey({ mods = "CTRL|SHIFT", key = "x" }) },
	-- {
	-- 	mods = "OPT|SHIFT",
	-- 	key = "LeftArrow",
	-- 	action = wezterm.action.Multiple({
	-- 		wezterm.action.ActivateCopyMode,
	-- 		wezterm.action.CopyMode({ SetSelectionMode = "Word" }),
	-- 		wezterm.action.CopyMode("MoveBackwardWord"),
	-- 	}),
	-- },

	{
		key = "LeftArrow",
		mods = "CMD|SHIFT",
		action = wezterm.action_callback(function(win, pane)
			win:perform_action(wezterm.action.CopyMode({ SetSelectionMode = "Line" }), pane)
			local selected_text = win:get_selection_text_for_pane(pane)
			wezterm.log_info("Hello from callback!")

			-- optional: trim text here
			win:copy_to_clipboard(selected_text)
			win:perform_action(wezterm.action.ClearSelection, pane)
			win:perform_action(wezterm.action.CopyMode("Close"), pane)
		end),
	},

	-- Neovim copy paste with command+c
	-- This will map Command + C to copy in normal and visual mode
	-- { key = "c", mods = "CMD", action = wezterm.action({ CopyTo = "Clipboard" }) },
	-- {
	-- 	key = "LeftArrow",
	-- 	mods = "OPT|SHIFT",
	-- 	action = wezterm.action.CopyMode({ MoveBackwardZoneOfType = "Input" }),
	-- },
	--

	-- CTRL+SHIFT+Space, followed by 'r' will put us in resize-pane
	-- mode until we cancel that mode.
	{
		key = "r",
		mods = "LEADER",
		action = act.ActivateKeyTable({
			name = "resize_pane",
			one_shot = false,
		}),
	},

	-- CTRL+SHIFT+Space, followed by 'w' will put us in activate-pane
	-- mode until we press some other key or until 1 second (1000ms)
	-- of time elapses
	-- // note: old way, use w to move around
	-- {
	-- 	key = "w",
	-- 	mods = "LEADER",
	-- 	action = act.ActivateKeyTable({
	-- 		name = "activate_pane",
	-- 		timeout_milliseconds = 1000,
	-- 	}),
	-- },
	-- CTRL+SHIFT+Space, followed by 'w' will put us in pane select, show alphabet to choose active
	{
		key = "w",
		mods = "LEADER",
		action = wezterm.action.PaneSelect({
			alphabet = "asdfghjkl;", -- home row keys, easy to reach
			mode = "Activate",
		}),
	},
	-- zoom active pane to fullscreen
	{
		key = "z",
		mods = "LEADER",
		action = wezterm.action.TogglePaneZoomState,
	},
	-- show that we are in zoomed state. (hard to tell otherwise there were other panes!)
	{
		key = "e",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Enter new tab name",
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},

	-- quick select mode (auto highlight common patters, select with 1 letter)
	{ key = "p", mods = "LEADER", action = act.QuickSelect },
	-- URL opening under cursor
	{ key = "o", mods = "LEADER", action = act.OpenLinkAtMouseCursor },

	-- Switch to last active tab
	{ key = "Tab", mods = "CTRL", action = act.ActivateLastTab },

	-- move pane to new tab
	{ key = "T", mods = "LEADER", action = act.PaneSelect({ mode = "MoveToNewTab" }) },

	{
		key = "n",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Enter workspace name",
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
				end
			end),
		}),
	},
	{ key = "W", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "WORKSPACES" }) },
}

config.inactive_pane_hsb = {
	saturation = 0.8,
	brightness = 0.4,
}

wezterm.on("format-tab-title", function(tab)
	local title = tab.active_pane.title

	if tab.active_pane.is_zoomed then
		return {
			{ Background = { Color = "#ff5555" } },
			{ Foreground = { Color = "#ffffff" } },
			{ Text = " 🔍🔍🔍🔍  ZOOMED 🔍🔍🔍🔍🔍" .. title },
		}
	end
end)

local search_mode = wezterm.gui.default_key_tables().search_mode

table.insert(search_mode, {
	key = "n",
	mods = "CTRL",
	action = act.CopyMode("NextMatch"),
})
table.insert(search_mode, {
	key = "p",
	mods = "CTRL",
	action = act.CopyMode("PriorMatch"),
})
table.insert(search_mode, {
	key = "Enter",
	mods = "SHIFT",
	action = act.CopyMode("NextMatch"),
})

config.key_tables = {
	-- Defines the keys that are active in our resize-pane mode.
	-- Since we're likely to want to make multiple adjustments,
	-- we made the activation one_shot=false. We therefore need
	-- to define a key assignment for getting out of this mode.
	-- 'resize_pane' here corresponds to the name="resize_pane" in
	-- the key assignments above.
	resize_pane = {
		{ key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 1 }) },
		{ key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },

		{ key = "RightArrow", action = act.AdjustPaneSize({ "Right", 1 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },

		{ key = "UpArrow", action = act.AdjustPaneSize({ "Up", 1 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },

		{ key = "DownArrow", action = act.AdjustPaneSize({ "Down", 1 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },

		-- Cancel the mode by pressing escape
		{ key = "Escape", action = "PopKeyTable" },
	},

	-- Defines the keys that are active in our activate-pane mode.
	-- 'activate_pane' here corresponds to the name="activate_pane" in
	-- the key assignments above.
	activate_pane = {
		{ key = "LeftArrow", action = act.ActivatePaneDirection("Left") },
		{ key = "h", action = act.ActivatePaneDirection("Left") },

		{ key = "RightArrow", action = act.ActivatePaneDirection("Right") },
		{ key = "l", action = act.ActivatePaneDirection("Right") },

		{ key = "UpArrow", action = act.ActivatePaneDirection("Up") },
		{ key = "k", action = act.ActivatePaneDirection("Up") },

		{ key = "DownArrow", action = act.ActivatePaneDirection("Down") },
		{ key = "j", action = act.ActivatePaneDirection("Down") },
	},

	-- copy_mode = {
	-- 	{ key = "e", mods = "SHIFT", action = act.CopyMode("MoveToEndOfLineContent") },
	-- },
	--

	search_mode = search_mode,
}

-- local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
--
-- tabline.setup()

return config
