return {
	-- Executables and native dependencies are managed by Nix, not Mason.
	{ "mason-org/mason.nvim", enabled = false },
	{ "mason-org/mason-lspconfig.nvim", enabled = false },
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				clangd = {
					mason = false,
					cmd = {
						"clangd",
						"--background-index",
						"--clang-tidy",
						"--function-arg-placeholders=true",
						"--query-driver=/nix/store/*-gcc-wrapper-*/bin/*,/nix/store/*-clang-wrapper-*/bin/*,/run/current-system/sw/bin/*",
					},
				},
				pyright = { mason = false },
				ruff = { mason = false },
				lua_ls = { mason = false },
				nil_ls = { mason = false },
			},
		},
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				python = { "ruff_format" },
				rust = { "rustfmt" },
				c = { "clang_format" },
				cpp = { "clang_format" },
				nix = { "nixfmt" },
			},
		},
	},
	{ "folke/snacks.nvim", opts = { image = { enabled = false } } },
}
