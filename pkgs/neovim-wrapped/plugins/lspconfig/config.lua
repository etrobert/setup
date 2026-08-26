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
		-- Show inferred types of const/let variables: const x: number = ...
		includeInlayVariableTypeHints = true,
		-- Suppress the above hint when the variable name already matches the type name: const user: User is redundant.
		includeInlayVariableTypeHintsWhenTypeMatchesName = false,
		-- Show inferred types on class property declarations: name: string.
		includeInlayPropertyDeclarationTypeHints = true,
		-- Show inferred return types on functions when not explicitly annotated: function foo(): string.
		includeInlayFunctionLikeReturnTypeHints = true,
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

local inlay_hint_max_length = 40

local orig_inlay_hint_handler = vim.lsp.handlers["textDocument/inlayHint"]
-- We override the inlay hint handler to filter out hints that are too long
vim.lsp.handlers["textDocument/inlayHint"] = function(err, result, ctx, config)
	if result then
		local client = vim.lsp.get_client_by_id(ctx.client_id)
		if client and client.name == "ts_ls" then
			result = vim.tbl_filter(function(hint)
				local text = table.concat(vim.tbl_map(function(p)
					return p.value
				end, hint.label))
				return #text <= inlay_hint_max_length
			end, result)
		end
	end
	orig_inlay_hint_handler(err, result, ctx, config)
end

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

-- Upstream's list is ast-grep's language ids, not neovim filetypes: .sh buffers
-- are `sh`, so shell rules never reached the editor.
vim.lsp.config("ast_grep", {
	filetypes = vim.list_extend({ "sh" }, vim.lsp.config.ast_grep.filetypes),
})

vim.lsp.enable({
	"ast_grep",
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
