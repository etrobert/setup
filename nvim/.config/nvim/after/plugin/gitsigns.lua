require("gitsigns").setup({
	current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`

	on_attach = function()
		local gitsigns = require("gitsigns")

		local wk = require("which-key")

		wk.register({
			h = {
				name = "Hunk",
				s = { gitsigns.stage_hunk, "Stage hunk" },
				r = { gitsigns.reset_hunk, "Reset hunk" },
				S = { gitsigns.stage_buffer, "Stage buffer" },
				u = { gitsigns.undo_stage_hunk, "Undo stage hunk" },
				R = { gitsigns.reset_buffer, "Reset buffer" },
				p = { gitsigns.preview_hunk, "Preview hunk" },
				d = { gitsigns.diffthis, "Diff this" },
			},
			td = { gitsigns.toggle_deleted, "Toggle deleted" },
		}, { prefix = "<leader>" })
	end,
})
