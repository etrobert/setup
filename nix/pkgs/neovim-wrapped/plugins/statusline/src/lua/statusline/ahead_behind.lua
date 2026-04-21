local M = {}

local cache = { ahead = 0, behind = 0 }
local last_update = 0

function M.update()
	local now = vim.uv.now()
	if now - last_update < 5000 then
		return
	end
	last_update = now
	local root = vim.fn.FugitiveWorkTree()
	if root == "" then
		return
	end
	vim.system(
		{ "git", "-C", root, "rev-list", "--count", "--left-right", "@{u}...HEAD" },
		{ text = true },
		function(out)
			if out.code == 0 and out.stdout then
				local behind, ahead = out.stdout:match("(%d+)%s+(%d+)")
				if behind then
					cache = { ahead = tonumber(ahead), behind = tonumber(behind) }
				end
			end
			vim.schedule(vim.cmd.redrawstatus)
		end
	)
end

function M.get()
	return cache
end

return M
