local p = require("catppuccin.palettes").get_palette("macchiato")

local modes = {
	Normal = p.blue,
	Insert = p.green,
	Visual = p.mauve,
	Command = p.red,
	Terminal = p.teal,
}

for name, color in pairs(modes) do
	-- Strong badge: dark text on mode color (mode label, loc)
	vim.api.nvim_set_hl(0, "StatuslineBadge" .. name, { fg = p.base, bg = color, bold = true })
	-- Surface: mode color on surface0 (right sep of badge, branch background)
	vim.api.nvim_set_hl(0, "StatuslineSurface" .. name, { fg = color, bg = p.surface0 })
	-- Badge entry sep: mode color on statusline bg (left sep pointing into badge)
	vim.api.nvim_set_hl(0, "StatuslineBadge" .. name .. "Sep", { fg = color })
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
}

local sep = "\u{E0B0}"
local sep_left = "\u{E0B2}"

local function mode_section()
	local name = mode_names[vim.fn.mode()] or "Normal"
	return "%#StatuslineBadge" .. name .. "# " .. vim.fn.mode() .. " %#StatuslineSurface" .. name .. "#" .. sep
end

local function branch_section()
	local name = mode_names[vim.fn.mode()] or "Normal"
	local branch = vim.b.gitsigns_head
	local content = (branch and branch ~= "") and (" \u{E0A0} " .. branch .. " ") or " "
	return "%#StatuslineSurface" .. name .. "#" .. content .. "%#StatuslineSurfaceSep#" .. sep .. "%*"
end

local function filetype_section()
	local ft = vim.bo.filetype
	local icon, hl = require("nvim-web-devicons").get_icon_by_filetype(ft, { default = true })
	return "%#" .. hl .. "#" .. icon .. "%* " .. ft
end

local function loc_section()
	local name = mode_names[vim.fn.mode()] or "Normal"
	return "%#StatuslineBadge" .. name .. "Sep#" .. sep_left .. "%#StatuslineBadge" .. name .. "# %l:%c "
end

-- gitsigns populates vim.b.gitsigns_head asynchronously, so the branch won't
-- show on first render. Force a redraw as soon as gitsigns has the data.
vim.api.nvim_create_autocmd("User", {
	pattern = "GitSignsUpdate",
	callback = function()
		vim.cmd.redrawstatus()
	end,
})

vim.opt.statusline = "%!v:lua.require'etrobert.statusline'.render()"

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
			loc_section(),
		})
	end,
}
