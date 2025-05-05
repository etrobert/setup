local M = {}

function M.gen_commit_msg()
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

function M.setup()
	vim.api.nvim_create_user_command("GenCommitMsg", M.gen_commit_msg, {})
end

return M
