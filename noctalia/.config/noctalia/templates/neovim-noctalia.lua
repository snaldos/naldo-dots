local M = {}

local palette = {
	mode = "{{mode}}",
	bg = "{{colors.terminal_background.default.hex}}",
	bg_dark = "{{colors.surface_container_lowest.default.hex}}",
	bg_low = "{{colors.surface_container_low.default.hex}}",
	bg_alt = "{{colors.surface_container.default.hex}}",
	bg_high = "{{colors.surface_container_high.default.hex}}",
	fg = "{{colors.terminal_foreground.default.hex}}",
	fg_muted = "{{colors.on_surface_variant.default.hex}}",
	primary = "{{colors.primary.default.hex}}",
	primary_container = "{{colors.primary_container.default.hex}}",
	on_primary_container = "{{colors.on_primary_container.default.hex}}",
	secondary = "{{colors.secondary.default.hex}}",
	on_secondary = "{{colors.on_secondary.default.hex}}",
	error = "{{colors.error.default.hex}}",
	outline_variant = "{{colors.outline_variant.default.hex}}",
	terminal = {
		black = "{{colors.terminal_normal_black.default.hex}}",
		black_bright = "{{colors.terminal_bright_black.default.hex}}",
		red = "{{colors.terminal_normal_red.default.hex}}",
		red_bright = "{{colors.terminal_bright_red.default.hex}}",
		green = "{{colors.terminal_normal_green.default.hex}}",
		green_bright = "{{colors.terminal_bright_green.default.hex}}",
		yellow = "{{colors.terminal_normal_yellow.default.hex}}",
		yellow_bright = "{{colors.terminal_bright_yellow.default.hex}}",
		blue = "{{colors.terminal_normal_blue.default.hex}}",
		blue_bright = "{{colors.terminal_bright_blue.default.hex}}",
		magenta = "{{colors.terminal_normal_magenta.default.hex}}",
		magenta_bright = "{{colors.terminal_bright_magenta.default.hex}}",
		cyan = "{{colors.terminal_normal_cyan.default.hex}}",
		cyan_bright = "{{colors.terminal_bright_cyan.default.hex}}",
		white = "{{colors.terminal_normal_white.default.hex}}",
		white_bright = "{{colors.terminal_bright_white.default.hex}}",
	},
}

local function valid_hex(color)
	return type(color) == "string" and color:match("^#%x%x%x%x%x%x$") ~= nil
end

local function blend(fg, bg, alpha)
	if not valid_hex(fg) or not valid_hex(bg) then
		return bg
	end

	local function channel(index, color)
		return tonumber(color:sub(index, index + 1), 16)
	end

	local r = math.floor(channel(2, fg) * alpha + channel(2, bg) * (1 - alpha) + 0.5)
	local g = math.floor(channel(4, fg) * alpha + channel(4, bg) * (1 - alpha) + 0.5)
	local b = math.floor(channel(6, fg) * alpha + channel(6, bg) * (1 - alpha) + 0.5)
	return string.format("#%02x%02x%02x", r, g, b)
end

local function transparent_enabled(configured)
	if vim.g.noctalia_transparent ~= nil then
		return vim.g.noctalia_transparent ~= false
	end
	return configured.transparent ~= false
end

local function apply_noctalia_colors(colors, transparent)
	local terminal = palette.terminal
	local blue = terminal.blue
	local cyan = terminal.cyan
	local green = terminal.green
	local magenta = terminal.magenta
	local red = terminal.red
	local yellow = terminal.yellow
	local teal = blend(cyan, green, 0.58)
	local orange = blend(yellow, red, 0.72)

	colors.bg = palette.bg
	colors.bg_dark = palette.bg_dark
	colors.bg_dark1 = blend(palette.bg_dark, palette.bg, 0.65)
	colors.bg_highlight = palette.bg_high
	colors.blue = blue
	colors.blue0 = blend(blue, palette.bg, 0.58)
	colors.blue1 = cyan
	colors.blue2 = teal
	colors.blue5 = terminal.cyan_bright
	colors.blue6 = blend(terminal.cyan_bright, palette.fg, 0.68)
	colors.blue7 = blend(blue, palette.bg, 0.38)
	colors.comment = blend(palette.fg_muted, palette.bg, 0.68)
	colors.cyan = cyan
	colors.dark3 = blend(palette.fg_muted, palette.bg, 0.46)
	colors.dark5 = blend(palette.fg_muted, palette.bg, 0.72)
	colors.fg = palette.fg
	colors.fg_dark = palette.fg_muted
	colors.fg_gutter = palette.outline_variant
	colors.green = green
	colors.green1 = teal
	colors.green2 = blend(teal, palette.bg, 0.72)
	colors.magenta = magenta
	colors.magenta2 = blend(magenta, red, 0.62)
	colors.orange = orange
	colors.purple = blend(magenta, palette.fg, 0.78)
	colors.red = red
	colors.red1 = palette.error
	colors.teal = teal
	colors.terminal_black = terminal.black_bright
	colors.yellow = yellow

	colors.none = "NONE"
	colors.black = palette.bg_dark
	colors.border = palette.outline_variant
	colors.border_highlight = palette.primary
	colors.bg_popup = palette.bg_alt
	colors.bg_statusline = palette.bg_low
	colors.bg_sidebar = transparent and colors.none or palette.bg_low
	colors.bg_float = palette.bg_alt
	colors.bg_visual = blend(palette.primary, palette.bg, 0.30)
	colors.bg_search = palette.primary_container
	colors.fg_sidebar = palette.fg_muted
	colors.fg_float = palette.fg

	colors.error = palette.error
	colors.todo = palette.primary
	colors.warning = yellow
	colors.info = cyan
	colors.hint = teal
	colors.diff = {
		add = blend(green, palette.bg, 0.18),
		delete = blend(red, palette.bg, 0.18),
		change = blend(blue, palette.bg, 0.16),
		text = blend(cyan, palette.bg, 0.28),
	}
	colors.git = {
		add = green,
		change = blue,
		delete = red,
		ignore = colors.dark3,
	}
	colors.rainbow = { red, orange, yellow, green, teal, cyan, blue, magenta }
	colors.terminal = vim.deepcopy(terminal)

	local util = require("tokyonight.util")
	util.bg = colors.bg
	util.fg = colors.fg
end

local function apply_noctalia_highlights(highlights, colors)
	highlights.Search = { bg = palette.primary_container, fg = palette.on_primary_container }
	highlights.IncSearch = { bg = palette.secondary, fg = palette.on_secondary, bold = true }
	highlights.CurSearch = "IncSearch"
	highlights.FloatBorder = { fg = palette.primary, bg = palette.bg_alt }
	highlights.FloatTitle = { fg = palette.primary, bg = palette.bg_alt, bold = true }

	-- todo-comments.nvim is not an upstream TokyoNight integration. Keep these
	-- groups small; all language, Treesitter, semantic-token, and supported
	-- plugin groups come directly from TokyoNight.
	highlights.TodoBgFIX = { fg = palette.bg, bg = palette.error, bold = true }
	highlights.TodoBgTODO = { fg = palette.bg, bg = colors.blue, bold = true }
	highlights.TodoBgWARN = { fg = palette.bg, bg = colors.warning, bold = true }
	highlights.TodoBgPERF = { fg = palette.bg, bg = colors.teal, bold = true }
	highlights.TodoBgNOTE = { fg = palette.bg, bg = colors.cyan, bold = true }
	highlights.TodoBgTEST = { fg = palette.bg, bg = colors.magenta, bold = true }
	highlights.TodoFgFIX = { fg = palette.error, bold = true }
	highlights.TodoFgTODO = { fg = colors.blue, bold = true }
	highlights.TodoFgWARN = { fg = colors.warning, bold = true }
	highlights.TodoFgPERF = { fg = colors.teal, bold = true }
	highlights.TodoFgNOTE = { fg = colors.cyan, bold = true }
	highlights.TodoFgTEST = { fg = colors.magenta, bold = true }
end

local function build_options()
	local ok, theme = pcall(require, "config.theme")
	local configured = ok and vim.deepcopy(theme.tokyonight and theme.tokyonight.opts or {}) or {}
	local previous_on_colors = configured.on_colors
	local previous_on_highlights = configured.on_highlights
	local transparent = transparent_enabled(configured)

	local opts = vim.tbl_deep_extend("force", {}, configured, {
		style = palette.mode == "light" and "day" or configured.style or "moon",
		light_style = "day",
		transparent = transparent,
		terminal_colors = true,
		cache = false,
		plugins = { auto = true },
	})

	opts.on_colors = function(colors)
		apply_noctalia_colors(colors, transparent)
		if type(previous_on_colors) == "function" then
			previous_on_colors(colors)
		end
	end
	opts.on_highlights = function(highlights, colors)
		apply_noctalia_highlights(highlights, colors)
		if type(previous_on_highlights) == "function" then
			previous_on_highlights(highlights, colors)
		end
	end
	return opts
end

local function refresh_integrations()
	pcall(function()
		require("bufferline").setup(require("bufferline").config)
	end)
	pcall(function()
		require("lualine").refresh({ place = { "statusline", "winbar", "tabline" } })
	end)
end

function M.setup()
	vim.o.background = palette.mode
	require("tokyonight").load(build_options())
	vim.g.colors_name = "matugen"

	vim.schedule(function()
		vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "matugen", modeline = false })
		refresh_integrations()
		vim.cmd("redraw!")
		vim.cmd("redrawstatus!")
	end)
end

local function matugen_enabled()
	local ok, theme = pcall(require, "config.theme")
	return ok and theme.backend == "matugen"
end

local function setup_signal()
	if _G.__noctalia_matugen_signal then
		return
	end

	local signal = vim.uv.new_signal()
	if not signal then
		return
	end

	_G.__noctalia_matugen_signal = signal
	signal:start("sigusr1", vim.schedule_wrap(function()
		if not matugen_enabled() then
			return
		end
		local ok, err = pcall(function()
			package.loaded["generated.matugen"] = nil
			require("generated.matugen").setup()
		end)
		if not ok then
			vim.notify(("Failed to reload Noctalia theme: %s"):format(err), vim.log.levels.ERROR)
		end
	end))
end

setup_signal()

return M
