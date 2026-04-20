local p = require("catppuccin.palettes").get_palette("macchiato")

local modes = {
	Normal = p.blue,
	Insert = p.green,
	Visual = p.mauve,
	Command = p.peach,
	Terminal = p.teal,
	Replace = p.red,
	Select = p.mauve,
	["O-Pending"] = p.blue,
}

for mode, color in pairs(modes) do
	-- Strong badge: dark text on mode color (mode label, loc)
	vim.api.nvim_set_hl(0, "StatuslineBadge" .. mode, { fg = p.base, bg = color, bold = true })
	-- Surface: mode color on surface0 (right sep of badge, branch background)
	vim.api.nvim_set_hl(0, "StatuslineSurface" .. mode, { fg = color, bg = p.surface0 })
end

-- Surface sep: surface0 on statusline bg (right sep out of surface)
vim.api.nvim_set_hl(0, "StatuslineSurfaceSep", { fg = p.surface0 })

local mode_names = {
	n = "Normal",
	i = "Insert",
	ic = "Insert",
	v = "Visual",
	V = "Visual",
	["\22"] = "Visual",
	c = "Command",
	t = "Terminal",
	R = "Replace",
	Rc = "Replace",
	Rx = "Replace",
	Rv = "Replace",
	Rvc = "Replace",
	Rvx = "Replace",
	ix = "Insert",
	s = "Select",
	S = "Select",
	["\19"] = "Select",
	no = "O-Pending",
	nov = "O-Pending",
	noV = "O-Pending",
	["\22o"] = "O-Pending",
}

local sep = "\u{E0B0}"
local sep_left = "\u{E0B2}"

local function mode_section()
	local mode = mode_names[vim.fn.mode(1)] or "Normal"
	return "%#StatuslineBadge" .. mode .. "# " .. mode:upper() .. " %#StatuslineSurface" .. mode .. "#" .. sep
end

local function branch_section()
	local mode = mode_names[vim.fn.mode(1)] or "Normal"
	-- gitsigns_head is a free variable read; FugitiveHead does a syscall on every render.
	-- Prefer gitsigns, fall back to Fugitive for unnamed buffers where gitsigns doesn't attach.
	local branch = vim.b.gitsigns_head or vim.fn.FugitiveHead()
	local content = (branch and branch ~= "") and (" \u{E725} " .. branch .. " ") or " "
	return "%#StatuslineSurface" .. mode .. "#" .. content .. "%#StatuslineSurfaceSep#" .. sep .. "%*"
end

local function filetype_section()
	local ft = vim.bo.filetype
	local icon, hl = require("nvim-web-devicons").get_icon_by_filetype(ft, { default = true })
	return "%#" .. hl .. "#" .. icon .. "%* " .. ft
end

local function progress_section()
	local mode = mode_names[vim.fn.mode(1)] or "Normal"
	local cur = vim.fn.line(".")
	local total = vim.fn.line("$")
	local pct = cur == 1 and "Top" or cur == total and "Bot" or "%p%%"
	return "%#StatuslineSurfaceSep#" .. sep_left .. "%#StatuslineSurface" .. mode .. "# " .. pct .. " "
end

local function loc_section()
	local mode = mode_names[vim.fn.mode(1)] or "Normal"
	return "%#StatuslineSurface" .. mode .. "#" .. sep_left .. "%#StatuslineBadge" .. mode .. "# %l:%c "
end

return {
	render = function()
		local active_win = vim.fn.win_getid()
		local status_win = vim.g.statusline_winid

		if status_win ~= active_win then
			return "%f"
		end

		return table.concat({
			mode_section(),
			branch_section(),
			" %f %= ",
			filetype_section(),
			" ",
			progress_section(),
			loc_section(),
		})
	end,
}
