local p = require("catppuccin.palettes").get_palette("macchiato")
vim.api.nvim_set_hl(0, "StatuslineModeNormal", { fg = p.base, bg = p.blue, bold = true })
vim.api.nvim_set_hl(0, "StatuslineModeNormalSep", { fg = p.blue })
vim.api.nvim_set_hl(0, "StatuslineModeInsert", { fg = p.base, bg = p.green, bold = true })
vim.api.nvim_set_hl(0, "StatuslineModeInsertSep", { fg = p.green })
vim.api.nvim_set_hl(0, "StatuslineModeVisual", { fg = p.base, bg = p.mauve, bold = true })
vim.api.nvim_set_hl(0, "StatuslineModeVisualSep", { fg = p.mauve })
vim.api.nvim_set_hl(0, "StatuslineModeCommand", { fg = p.base, bg = p.red, bold = true })
vim.api.nvim_set_hl(0, "StatuslineModeCommandSep", { fg = p.red })
vim.api.nvim_set_hl(0, "StatuslineModeTerminal", { fg = p.base, bg = p.teal, bold = true })
vim.api.nvim_set_hl(0, "StatuslineModeTerminalSep", { fg = p.teal })

local mode_hls = {
	n = "StatuslineModeNormal",
	i = "StatuslineModeInsert",
	ic = "StatuslineModeInsert",
	v = "StatuslineModeVisual",
	V = "StatuslineModeVisual",
	["\22"] = "StatuslineModeVisual",
	c = "StatuslineModeCommand",
	t = "StatuslineModeTerminal",
}

local sep = "\u{E0B0}"

local function mode_section()
	local m = vim.fn.mode()
	local hl = mode_hls[m] or "StatusLine"
	return "%#" .. hl .. "# " .. m .. " %#" .. hl .. "Sep#" .. sep .. "%*"
end

local function filetype_section()
	local ft = vim.bo.filetype
	local icon, hl = require("nvim-web-devicons").get_icon_by_filetype(ft, { default = true })
	return "%#" .. hl .. "#" .. icon .. "%* %y"
end

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
			" %f %= ",
			filetype_section(),
			" %l:%c",
		})
	end,
}
