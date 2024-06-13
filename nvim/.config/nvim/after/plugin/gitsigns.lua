require("gitsigns").setup({
	current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`

	on_attach = function(bufnr)
		local gitsigns = require("gitsigns")

		local wk = require("which-key")

		local function map(mode, l, r, opts)
			opts = opts or {}
			opts.buffer = bufnr
			vim.keymap.set(mode, l, r, opts)
		end

		-- Navigation
		map("n", "]c", function()
			if vim.wo.diff then
				vim.cmd.normal({ "]c", bang = true })
			else
				gitsigns.nav_hunk("next")
			end
		end)

		map("n", "[c", function()
			if vim.wo.diff then
				vim.cmd.normal({ "[c", bang = true })
			else
				gitsigns.nav_hunk("prev")
			end
		end)

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
