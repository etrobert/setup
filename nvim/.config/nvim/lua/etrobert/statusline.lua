local p = require("catppuccin.palettes").get_palette("macchiato")

-- Mode badge: dark text on mode color
vim.api.nvim_set_hl(0, "StatuslineModeNormal", { fg = p.base, bg = p.blue, bold = true })
vim.api.nvim_set_hl(0, "StatuslineModeInsert", { fg = p.base, bg = p.green, bold = true })
vim.api.nvim_set_hl(0, "StatuslineModeVisual", { fg = p.base, bg = p.mauve, bold = true })
vim.api.nvim_set_hl(0, "StatuslineModeCommand", { fg = p.base, bg = p.red, bold = true })
vim.api.nvim_set_hl(0, "StatuslineModeTerminal", { fg = p.base, bg = p.teal, bold = true })

-- Mode sep: mode color → surface0 (branch background)
vim.api.nvim_set_hl(0, "StatuslineModeNormalSep", { fg = p.blue, bg = p.surface0 })
vim.api.nvim_set_hl(0, "StatuslineModeInsertSep", { fg = p.green, bg = p.surface0 })
vim.api.nvim_set_hl(0, "StatuslineModeVisualSep", { fg = p.mauve, bg = p.surface0 })
vim.api.nvim_set_hl(0, "StatuslineModeCommandSep", { fg = p.red, bg = p.surface0 })
vim.api.nvim_set_hl(0, "StatuslineModeTerminalSep", { fg = p.teal, bg = p.surface0 })

-- Branch badge: mode color text on surface0
vim.api.nvim_set_hl(0, "StatuslineBranchNormal", { fg = p.blue, bg = p.surface0 })
vim.api.nvim_set_hl(0, "StatuslineBranchInsert", { fg = p.green, bg = p.surface0 })
vim.api.nvim_set_hl(0, "StatuslineBranchVisual", { fg = p.mauve, bg = p.surface0 })
vim.api.nvim_set_hl(0, "StatuslineBranchCommand", { fg = p.red, bg = p.surface0 })
vim.api.nvim_set_hl(0, "StatuslineBranchTerminal", { fg = p.teal, bg = p.surface0 })

-- Branch sep: surface0 → statusline background
vim.api.nvim_set_hl(0, "StatuslineBranchSep", { fg = p.surface0 })

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

local branch_hls = {
	n = "StatuslineBranchNormal",
	i = "StatuslineBranchInsert",
	ic = "StatuslineBranchInsert",
	v = "StatuslineBranchVisual",
	V = "StatuslineBranchVisual",
	["\22"] = "StatuslineBranchVisual",
	c = "StatuslineBranchCommand",
	t = "StatuslineBranchTerminal",
}

local sep = "\u{E0B0}"

local function mode_section()
	local m = vim.fn.mode()
	local hl = mode_hls[m] or "StatusLine"
	return "%#" .. hl .. "# " .. m .. " %#" .. hl .. "Sep#" .. sep
end

local function branch_section()
	local m = vim.fn.mode()
	local hl = branch_hls[m] or "StatusLine"
	local branch = vim.b.gitsigns_head
	local content = (branch and branch ~= "") and (" " .. branch .. " ") or " "
	return "%#" .. hl .. "#" .. content .. "%#StatuslineBranchSep#" .. sep .. "%*"
end

local function filetype_section()
	local ft = vim.bo.filetype
	local icon, hl = require("nvim-web-devicons").get_icon_by_filetype(ft, { default = true })
	return "%#" .. hl .. "#" .. icon .. "%* " .. ft
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
			" %l:%c",
		})
	end,
}
