return {
	"lewis6991/gitsigns.nvim",
	opts = {
		current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`

		on_attach = function(bufnr)
			local gitsigns = require("gitsigns")

			local wk = require("which-key")

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

			wk.add({
				{ "]c", nextHunk, desc = "Next hunk", buffer = bufnr },
				{ "[c", previousHunk, desc = "Previous hunk", buffer = bufnr },

				{ "<leader>h", group = "Hunk" },
				{ "<leader>hs", gitsigns.stage_hunk, desc = "Stage hunk" },
				{ "<leader>hr", gitsigns.reset_hunk, desc = "Reset hunk" },
				{ "<leader>hS", gitsigns.stage_buffer, desc = "Stage buffer" },
				{ "<leader>hu", gitsigns.undo_stage_hunk, desc = "Undo stage hunk" },
				{ "<leader>hR", gitsigns.reset_buffer, desc = "Reset buffer" },
				{ "<leader>hp", gitsigns.preview_hunk, desc = "Preview hunk" },
				{ "<leader>hd", gitsigns.diffthis, desc = "Diff this" },

				{ "<leader>td", gitsigns.toggle_deleted, desc = "Toggle deleted" },
			})
		end,
	},
}
