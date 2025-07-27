vim.g.mapleader = " "
vim.keymap.set("i", "jj", "<Esc>")
vim.keymap.set("n", "-", vim.cmd.Ex, { desc = "Open netrw file explorer" })

vim.keymap.set("n", "<leader>n", vim.cmd.nohlsearch, { desc = "Remove Search Highlight" })

-- Buffers

local function delete_all_buffers()
	vim.cmd.bufdo("bd")
end

local function delete_other_buffers()
	local current_buf = vim.fn.bufnr("%")
	vim.cmd("bufdo if bufnr() != " .. current_buf .. " | bd | endif")
end

vim.keymap.set("n", "<leader>bn", vim.cmd.bnext, { desc = "Next Buffer" })
vim.keymap.set("n", "<leader>bp", vim.cmd.bprev, { desc = "Previous Buffer" })
vim.keymap.set("n", "<leader>bd", vim.cmd.bd, { desc = "Delete Buffer" })
vim.keymap.set("n", "<leader>ba", delete_all_buffers, { desc = "Delete All Buffers" })
vim.keymap.set("n", "<leader>bo", delete_other_buffers, { desc = "Delete Other Buffers" })

function DeleteCurrentFile()
	local file = vim.fn.expand("%:p")
	if file == "" then
		vim.notify("Can't find filename to delete", vim.log.levels.WARN)
		return
	end
	if vim.fn.delete(file) == -1 then
		vim.notify("File " .. file .. " could not be deleted", vim.log.levels.ERROR)
		return
	end
	vim.cmd("bd")
	vim.notify("Deleted " .. file, vim.log.levels.INFO)
end

vim.keymap.set("n", "<leader>rm", DeleteCurrentFile, { desc = "Delete current file" })

-- Source: https://lsp-zero.netlify.app/v3.x/blog/you-might-not-need-lsp-zero.html

vim.api.nvim_create_autocmd("LspAttach", {
	desc = "LSP actions",
	callback = function(event)
		local opts = { buffer = event.buf }

		-- these will be buffer-local keybindings
		-- because they only work if you have an active language server

		vim.keymap.set("n", "gd", function()
			vim.lsp.buf.definition()
		end, opts)
		vim.keymap.set("n", "gD", function()
			vim.lsp.buf.declaration()
		end, opts)
		vim.keymap.set("n", "go", function()
			vim.lsp.buf.type_definition()
		end, opts)
		vim.keymap.set("n", "gs", function()
			vim.lsp.buf.signature_help()
		end, opts)
		vim.keymap.set({ "n", "x" }, "<F3>", function()
			vim.lsp.buf.format({ async = true })
		end, opts)
	end,
})

function OpenPluginGithub()
	local line = vim.fn.getline(".")
	local repo = line:match('"([^/]+/[^"]+)"')

	if repo then
		local url = "https://github.com/" .. repo
		vim.fn.system("open " .. url)
		vim.notify("Opening: " .. url, vim.log.levels.INFO)
	else
		vim.notify("No GitHub repository found on current line", vim.log.levels.WARN)
	end
end

-- Create command and mapping
vim.api.nvim_create_user_command("OpenPluginGithub", OpenPluginGithub, {})
vim.keymap.set("n", "<leader>pg", OpenPluginGithub, { desc = "Open plugin GitHub page" })

function CopyFileLine()
	local file_line = vim.fn.expand("%") .. ":" .. vim.fn.line(".")

	vim.fn.setreg("+", file_line)
	vim.notify("Copied: " .. file_line)
end

vim.api.nvim_create_user_command("CopyFileLine", CopyFileLine, {})
vim.keymap.set("n", "<leader>y", CopyFileLine, { desc = "Copy file and line number" })

-- Auto-remove trailing whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	command = [[%s/\s\+$//e]],
})

-- Get information about the current markdown code block
function GetCurrentCodeBlock()
	local line = vim.fn.line(".")
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	-- Find code block boundaries
	local start_line, end_line, lang = nil, nil, nil

	-- Look backward for opening ```
	for i = line, 1, -1 do
		if lines[i]:match("^```(%w*)") then
			start_line = i
			lang = lines[i]:match("^```(%w+)")
			break
		end
	end

	-- Look forward for closing ```
	if start_line then
		for i = line, #lines do
			if lines[i]:match("^```%s*$") and i > start_line then
				end_line = i
				break
			end
		end
	end

	-- Return nil if no complete code block found
	if not (start_line and end_line and lang) then
		return nil
	end

	-- Extract code lines
	local code_lines = {}
	for i = start_line + 1, end_line - 1 do
		table.insert(code_lines, lines[i])
	end

	return {
		language = lang,
		code = table.concat(code_lines, "\n"),
		start_line = start_line,
		end_line = end_line,
		lines = code_lines,
	}
end

-- Execute markdown code blocks
function ExecuteCodeBlock()
	local block = GetCurrentCodeBlock()

	if not block then
		vim.notify("No code block found at cursor", vim.log.levels.WARN)
		return
	end

	-- Execute based on language directly (shows output automatically)
	if block.language == "bash" or block.language == "sh" then
		vim.cmd("!bash -c " .. vim.fn.shellescape(block.code))
	elseif block.language == "javascript" or block.language == "js" then
		vim.cmd("!node -e " .. vim.fn.shellescape(block.code))
	elseif block.language == "python" then
		vim.cmd("!python3 -c " .. vim.fn.shellescape(block.code))
	else
		vim.notify("Unsupported language: " .. block.language, vim.log.levels.WARN)
		return
	end
end

vim.keymap.set("n", "<leader>ex", ExecuteCodeBlock, { desc = "Execute markdown code block" })
