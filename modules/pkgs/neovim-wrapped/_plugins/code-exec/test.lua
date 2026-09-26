local t = require("harness")
local code_exec = require("code_exec")

local function block_at(lines, lnum)
	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
	vim.api.nvim_win_set_cursor(0, { lnum, 0 })
	return code_exec.get_current_code_block()
end

local two_blocks = { "```python", "print(1)", "```", "", "```bash", "echo 2", "```" }

t.eq("inside the first block", { language = "python", code = "print(1)" }, block_at(two_blocks, 2))
t.eq("on the opening fence", { language = "python", code = "print(1)" }, block_at(two_blocks, 1))
t.eq("inside a later block", { language = "bash", code = "echo 2" }, block_at(two_blocks, 6))

t.eq(
	"multi-line body",
	{ language = "sh", code = "one\ntwo\nthree" },
	block_at({ "```sh", "one", "two", "three", "```" }, 3)
)

t.eq("empty body", { language = "sh", code = "" }, block_at({ "```sh", "```" }, 1))
t.eq("fence with no language", { language = nil, code = "plain" }, block_at({ "```", "plain", "```" }, 2))

t.eq("no fences at all", nil, block_at({ "just text", "more text" }, 1))
t.eq("unclosed block", nil, block_at({ "```python", "print(1)" }, 2))
t.eq("above every fence", nil, block_at({ "intro", "```sh", "echo", "```" }, 1))

-- `.md` prose is full of indented fences inside lists; only column 0 opens a block.
t.eq("indented fence does not open a block", nil, block_at({ "  ```sh", "  echo", "  ```" }, 2))

local function selection(lines, first, last)
	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
	vim.api.nvim_win_set_cursor(0, { first, 0 })
	vim.cmd(("normal! V%dG\27"):format(last))
	return code_exec.get_visual_selection()
end

t.eq("selection is linewise", "two\nthree", selection({ "one", "two", "three", "four" }, 2, 3))
t.eq("single-line selection", "one", selection({ "one", "two" }, 1, 1))

t.done()
