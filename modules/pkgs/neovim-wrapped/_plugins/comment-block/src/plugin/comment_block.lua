-- Treesitter's `ac` matches a single comment node, so on a run of stacked line
-- comments it only ever grabs one line. `aC` takes the whole run.

local function node_at_indent(parser, lnum)
	local col = vim.fn.getline(lnum):find("%S")
	if not col then
		return nil
	end

	local range = { lnum - 1, col - 1, lnum - 1, col }

	-- Most grammars inject the `comment` language into comment bodies,
	-- which hides the host language's own comment node.
	local tree = parser:language_for_range(range)
	while tree and tree:lang() == "comment" do
		tree = tree:parent()
	end

	return tree and tree:named_node_for_range(range)
end

local function select_comment_block()
	local parser = vim.treesitter.get_parser()
	if not parser then
		return
	end

	parser:parse(true)

	local function is_comment(lnum)
		local line = vim.fn.getline(lnum)

		-- Treesitter reports a shebang as an ordinary comment node.
		if lnum == 1 and line:find("^#!") then
			return false
		end

		local node = node_at_indent(parser, lnum)
		if not node or not node:type():lower():find("comment") then
			return false
		end

		local content_end = line:find("%s*$") - 1
		local srow, _, erow, ecol = node:range()

		-- Some grammars end the node on the next row, having eaten the newline.
		return (erow == srow and ecol >= content_end) or (erow == srow + 1 and ecol == 0)
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

	vim.cmd("normal! \27" .. first .. "GV" .. last .. "G")
end

vim.keymap.set({ "x", "o" }, "aC", select_comment_block, { desc = "a comment block" })
