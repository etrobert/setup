-- Treesitter's `ac` matches a single comment node, so on a run of stacked line
-- comments it only ever grabs one line. `aC` takes the whole run.

local function commentstring()
	local ok, parser = pcall(vim.treesitter.get_parser, 0)
	if not ok or not parser then
		return vim.bo.commentstring
	end

	pcall(parser.parse, parser, true)

	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local tree = parser:language_for_range({ row - 1, col, row - 1, col })
	for _, ft in ipairs(vim.treesitter.language.get_filetypes(tree:lang())) do
		local cs = vim.filetype.get_option(ft, "commentstring")
		if cs ~= "" then
			return cs
		end
	end

	return vim.bo.commentstring
end

-- Both ends are required, so a line that merely opens a multi-line block
-- comment does not read as a whole one.
local function comment_pattern()
	local left, right = commentstring():match("^(.-)%%s(.-)$")
	if not left then
		return nil
	end

	local l, r = vim.trim(vim.pesc(left)), vim.trim(vim.pesc(right))
	if l == "" then
		return nil
	end

	return "^%s-" .. l .. ".*" .. r .. "%s-$"
end

local function select_comment_block()
	if vim.fn.mode():match("^[vV\22]") then
		vim.cmd("normal! \27")
	end

	local pattern = comment_pattern()
	if not pattern then
		return
	end

	local function is_comment(lnum)
		return vim.fn.getline(lnum):find(pattern) ~= nil
	end

	if not is_comment(vim.fn.line(".")) then
		return
	end

	local first = vim.fn.line(".")
	while first > 1 and is_comment(first - 1) do
		first = first - 1
	end

	local last = vim.fn.line(".")
	while last < vim.fn.line("$") and is_comment(last + 1) do
		last = last + 1
	end

	vim.cmd("normal! " .. first .. "GV" .. last .. "G")
end

vim.keymap.set({ "x", "o" }, "aC", select_comment_block, { desc = "a comment block" })
