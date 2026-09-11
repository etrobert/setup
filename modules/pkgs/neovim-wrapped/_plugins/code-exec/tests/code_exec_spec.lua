local code_exec = require("code_exec")

local function block_at(lines, lnum)
	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
	vim.api.nvim_win_set_cursor(0, { lnum, 0 })
	return code_exec.get_current_code_block()
end

describe("get_current_code_block", function()
	local two_blocks = { "```python", "print(1)", "```", "", "```bash", "echo 2", "```" }

	it("finds the block the cursor is inside", function()
		assert.are.same({ language = "python", code = "print(1)" }, block_at(two_blocks, 2))
	end)

	it("finds the block from its opening fence", function()
		assert.are.same({ language = "python", code = "print(1)" }, block_at(two_blocks, 1))
	end)

	it("finds a later block", function()
		assert.are.same({ language = "bash", code = "echo 2" }, block_at(two_blocks, 6))
	end)

	it("joins a multi-line body", function()
		assert.are.same(
			{ language = "sh", code = "one\ntwo\nthree" },
			block_at({ "```sh", "one", "two", "three", "```" }, 3)
		)
	end)

	it("handles an empty body", function()
		assert.are.same({ language = "sh", code = "" }, block_at({ "```sh", "```" }, 1))
	end)

	it("leaves the language nil on a bare fence", function()
		assert.are.same({ language = nil, code = "plain" }, block_at({ "```", "plain", "```" }, 2))
	end)

	it("returns nil when there are no fences", function()
		assert.is_nil(block_at({ "just text", "more text" }, 1))
	end)

	it("returns nil for an unclosed block", function()
		assert.is_nil(block_at({ "```python", "print(1)" }, 2))
	end)

	it("returns nil above every fence", function()
		assert.is_nil(block_at({ "intro", "```sh", "echo", "```" }, 1))
	end)

	-- `.md` prose is full of indented fences inside lists; only column 0 opens a block.
	it("ignores an indented fence", function()
		assert.is_nil(block_at({ "  ```sh", "  echo", "  ```" }, 2))
	end)
end)

describe("get_visual_selection", function()
	local function selection(lines, first, last)
		vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
		vim.api.nvim_win_set_cursor(0, { first, 0 })
		vim.cmd(("normal! V%dG\27"):format(last))
		return code_exec.get_visual_selection()
	end

	it("is linewise", function()
		assert.are.same("two\nthree", selection({ "one", "two", "three", "four" }, 2, 3))
	end)

	it("handles a single line", function()
		assert.are.same("one", selection({ "one", "two" }, 1, 1))
	end)
end)
