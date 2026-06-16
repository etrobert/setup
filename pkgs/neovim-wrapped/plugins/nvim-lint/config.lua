require("lint").linters_by_ft = {
	markdown = { "markdownlint-cli2" },
	yaml = { "yamllint" },
	nix = { "statix" },
}

vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
	callback = function()
		require("lint").try_lint()
	end,
})
