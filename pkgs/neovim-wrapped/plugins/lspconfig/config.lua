vim.lsp.config("gopls", {
	settings = {
		gopls = {
			codelenses = {
				gc_details = true,
				generate = true,
				test = true,
				tidy = true,
				upgrade_dependency = true,
			},
			hints = {
				assignVariableTypes = true,
				compositeLiteralFields = true,
				compositeLiteralTypes = true,
				constantValues = true,
				functionTypeParameters = true,
				parameterNames = true,
				rangeVariableTypes = true,
			},
		},
	},
})

local ts_ls_opts = {
	inlayHints = {
		-- Show argument labels at call sites: foo(/*timeout:*/ 1000). "all" shows for every arg, "literals" only for literal values.
		includeInlayParameterNameHints = "all",
		-- Suppress the above hint when the variable name already matches the parameter name: foo(timeout) needs no label.
		includeInlayParameterNameHintsWhenArgumentMatchesName = false,
		-- Show types of parameters in function signatures: (x: number, y: string).
		includeInlayFunctionParameterTypeHints = true,
		-- Show inferred types on class property declarations: name: string.
		includeInlayPropertyDeclarationTypeHints = true,
		-- Show numeric values of enum members: Red = 0, Green = 1.
		includeInlayEnumMemberValueHints = true,
	},
}

vim.lsp.config("ts_ls", {
	settings = {
		typescript = ts_ls_opts,
		javascript = ts_ls_opts,
	},
})

-- Upstream counts markdown as an HTML language, for inline `class` attributes.
vim.lsp.config("tailwindcss", {
	filetypes = vim.tbl_filter(function(ft)
		return ft ~= "markdown" and ft ~= "mdx"
	end, vim.lsp.config.tailwindcss.filetypes),
})

vim.lsp.config("nixd", {
	settings = {
		nixd = {
			options = {
				nixos = {
					expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.tower.options",
				},
				darwin = {
					expr = "(builtins.getFlake (builtins.toString ./.)).darwinConfigurations.aaron.options",
				},
			},
		},
	},
})

vim.lsp.enable({
	"bashls",
	"eslint",
	"tailwindcss",
	"ts_ls",
	"rust_analyzer",
	"gopls",
	"lua_ls",
	"marksman",
	"nixd",
	"openscad_lsp",
	"cssls",
	"html",
	"texlab",
	"taplo",
	"dockerls",
	"copilot",
})
