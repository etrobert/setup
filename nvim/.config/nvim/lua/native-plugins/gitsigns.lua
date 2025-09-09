vim.pack.add({ "https://github.com/lewis6991/gitsigns.nvim" })

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

		vim.keymap.set("n", "]c", nextHunk, { buffer = bufnr, desc = "Next hunk" })
		vim.keymap.set("n", "[c", previousHunk, { buffer = bufnr, desc = "Previous hunk" })

		vim.keymap.set("n", "<leader>hs", gitsigns.stage_hunk, { buffer = bufnr, desc = "Stage hunk" })
		vim.keymap.set("n", "<leader>hr", gitsigns.reset_hunk, { buffer = bufnr, desc = "Reset hunk" })
		vim.keymap.set("n", "<leader>hS", gitsigns.stage_buffer, { buffer = bufnr, desc = "Stage buffer" })
		vim.keymap.set("n", "<leader>hu", gitsigns.undo_stage_hunk, { buffer = bufnr, desc = "Undo stage hunk" })
		vim.keymap.set("n", "<leader>hR", gitsigns.reset_buffer, { buffer = bufnr, desc = "Reset buffer" })
		vim.keymap.set("n", "<leader>hp", gitsigns.preview_hunk, { buffer = bufnr, desc = "Preview hunk" })
		vim.keymap.set("n", "<leader>hd", gitsigns.diffthis, { buffer = bufnr, desc = "Diff this" })

		vim.keymap.set("n", "<leader>td", gitsigns.toggle_deleted, { buffer = bufnr, desc = "Toggle deleted" })

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
		end, { buffer = bufnr, desc = "Toggle base (HEAD <-> merge-base)" })
	end,
})
