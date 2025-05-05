vim.g.mapleader = " "
vim.keymap.set("i", "jj", "<Esc>")

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

---@param opts { args: string }
function Ask(opts)
	if not os.getenv("OPENAI_API_KEY") or os.getenv("OPENAI_API_KEY") == "" then
		vim.notify("Missing OPENAI_API_KEY environment variable.", vim.log.levels.ERROR)
		return
	end

	local curl = require("plenary.curl")
	local user_message = opts.args ~= "" and opts.args or vim.fn.input("Prompt: ")
	local buffer_content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
	local prompt = user_message .. "\n\nCurrent file:\n\n" .. buffer_content

	local response = curl.post("https://api.openai.com/v1/chat/completions", {
		headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = "Bearer " .. os.getenv("OPENAI_API_KEY"),
		},
		body = vim.fn.json_encode({
			model = "gpt-4.1",
			messages = {
				{
					role = "system",
					content = [[
You are a code assistant.
Keep your response line length under 80 characters,
break lines with a newline if needed.
Use markdown formatting.
]],
				},
				{ role = "user", content = prompt },
			},
			max_tokens = 750,
		}),
		timeout = 20000,
	})

	if response.status ~= 200 then
		vim.notify("Error: " .. response.status .. " - " .. response.body, vim.log.levels.ERROR)
		return
	end

	local output = vim.fn.json_decode(response.body).choices[1].message.content
	vim.cmd("vnew")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(output, "\n"))
	vim.api.nvim_set_option_value("filetype", "markdown", {})
	vim.api.nvim_set_option_value("buftype", "nofile", {})
end

vim.api.nvim_create_user_command("Ask", Ask, { nargs = "*" })

function GenCommitMsg()
	local curl = require("plenary.curl")
	local diff = vim.fn.system("git diff --cached")

	if diff == "" then
		vim.notify("No staged changes to commit.", vim.log.levels.INFO)
		return
	end

	local recent_commits = vim.fn.system("git log --pretty=format:'%s' -n 5")

	local prompt = "Here are some recent commits for style reference:\n\n"
		.. recent_commits
		.. "Write a clear commit message for this diff:\n\n"
		.. diff

	local response = curl.post("https://api.openai.com/v1/chat/completions", {
		headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = "Bearer " .. os.getenv("OPENAI_API_KEY"),
		},
		body = vim.fn.json_encode({
			model = "gpt-4.1",
			messages = {
				{
					role = "system",
					content = "You generate commit messages. Only respond with the commit message.",
				},
				{ role = "user", content = prompt },
			},
			max_tokens = 100,
		}),
	})

	if response.status ~= 200 then
		vim.notify("Error: " .. response.status .. " - " .. response.body, vim.log.levels.ERROR)
		return
	end

	local output = vim.fn.json_decode(response.body).choices[1].message.content

	local tmp_file = vim.fn.tempname()
	local fd = io.open(tmp_file, "w")
	if not fd then
		vim.notify("Failed to open temporary file.", vim.log.levels.ERROR)
		return
	end
	fd:write(output)
	fd:close()

	vim.cmd("Git commit -F " .. vim.fn.shellescape(tmp_file) .. " --edit")

	os.remove(tmp_file)
end

vim.api.nvim_create_user_command("GenCommitMsg", GenCommitMsg, {})
