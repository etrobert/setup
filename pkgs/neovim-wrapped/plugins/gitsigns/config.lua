require("gitsigns").setup({
	current_line_blame = true,
	on_attach = function(bufnr)
		local gitsigns = require("gitsigns")

		local function previousHunk()
			if vim.wo.diff then
				vim.cmd.normal({ "[c", bang = true })
			else
				gitsigns.nav_hunk("prev")
			end
		end

		local function nextHunk()
			if vim.wo.diff then
				vim.cmd.normal({ "]c", bang = true })
			else
				gitsigns.nav_hunk("next")
			end
		end

		vim.keymap.set("n", "]c", nextHunk, { buf = bufnr, desc = "Next hunk" })
		vim.keymap.set("n", "[c", previousHunk, { buf = bufnr, desc = "Previous hunk" })

		vim.keymap.set("n", "<leader>hs", gitsigns.stage_hunk, { buf = bufnr, desc = "Stage hunk" })
		vim.keymap.set("n", "<leader>hr", gitsigns.reset_hunk, { buf = bufnr, desc = "Reset hunk" })
		vim.keymap.set("n", "<leader>hS", gitsigns.stage_buffer, { buf = bufnr, desc = "Stage buffer" })
		vim.keymap.set("n", "<leader>hR", gitsigns.reset_buffer, { buf = bufnr, desc = "Reset buffer" })
		vim.keymap.set("n", "<leader>hp", gitsigns.preview_hunk, { buf = bufnr, desc = "Preview hunk" })
		vim.keymap.set("n", "<leader>hi", gitsigns.preview_hunk_inline, { buf = bufnr, desc = "Preview hunk inline" })
		vim.keymap.set("n", "<leader>hd", gitsigns.diffthis, { buf = bufnr, desc = "Diff this" })

		vim.keymap.set("n", "<leader>hb", function()
			local current_base = require("gitsigns.config").config.base
			if current_base == nil then
				local merge_base = vim.fn.trim(vim.fn.system("git merge-base origin/main HEAD"))
				gitsigns.change_base(merge_base, true)
				vim.notify("Gitsigns base: " .. merge_base)
			else
				gitsigns.change_base(nil, true)
				vim.notify("Gitsigns base: HEAD")
			end
		end, { buf = bufnr, desc = "Toggle base (HEAD <-> merge-base)" })
	end,
})

-- -- Auto-refresh gitsigns when nvim gains focus
-- vim.api.nvim_create_autocmd("FocusGained", {
-- 	callback = function()
-- 		require("gitsigns").reset_base()
-- 	end,
-- })
