return {
	"lewis6991/gitsigns.nvim",
	opts = {
		current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`

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

			-- Toggle between merge-base and HEAD as base
			vim.keymap.set("n", "<leader>hb", function()
				local current_base = require("gitsigns.config").config.base
				if current_base == nil then
					local merge_base = vim.fn.trim(vim.fn.system("git merge-base origin/main HEAD"))
					gitsigns.change_base(merge_base, true)
					print("Gitsigns base: " .. merge_base)
				else
					gitsigns.change_base(nil, true)
					print("Gitsigns base: HEAD")
				end
			end, { buffer = bufnr, desc = "Toggle base (HEAD <-> merge-base)" })
		end,
	},
}
