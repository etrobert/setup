-- Catppuccin Macchiato palette colors
vim.api.nvim_set_hl(0, "StatuslineModeNormal", { fg = "#24273a", bg = "#8aadf4", bold = true })
vim.api.nvim_set_hl(0, "StatuslineModeInsert", { fg = "#24273a", bg = "#a6da95", bold = true })
vim.api.nvim_set_hl(0, "StatuslineModeVisual", { fg = "#24273a", bg = "#c6a0f6", bold = true })
vim.api.nvim_set_hl(0, "StatuslineModeCommand", { fg = "#24273a", bg = "#ed8796", bold = true })
vim.api.nvim_set_hl(0, "StatuslineModeTerminal", { fg = "#24273a", bg = "#8bd5ca", bold = true })

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

local function mode_section()
	local m = vim.fn.mode()
	local hl = mode_hls[m] or "StatusLine"
	return "%#" .. hl .. "# " .. m .. " %*"
end

_G.Statusline = { mode_section = mode_section }

vim.opt.statusline = "%{%v:lua.Statusline.mode_section()%} %f"
