return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = false,
		opts = function(_, opts)
			opts.ensure_installed = {}
			opts.install_dir = vim.g.uontabc_treesitter_runtime
		end,
	},
	{ "mrcjkb/rustaceanvim", enabled = vim.fn.executable("rust-analyzer") == 1 },
	-- Executables and native dependencies are managed by Nix, not Mason.
	{ "mason-org/mason.nvim", enabled = false },
	{ "mason-org/mason-lspconfig.nvim", enabled = false },
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				clangd = {
					enabled = vim.fn.executable("clangd") == 1,
					mason = false,
					cmd = {
						"clangd",
						"--background-index",
						"--clang-tidy",
						"--function-arg-placeholders=true",
						"--query-driver=/nix/store/*-gcc-wrapper-*/bin/*,/nix/store/*-clang-wrapper-*/bin/*,/run/current-system/sw/bin/*",
					},
				},
				pyright = { mason = false, enabled = vim.fn.executable("pyright-langserver") == 1 },
				ruff = { mason = false, enabled = vim.fn.executable("ruff") == 1 },
				lua_ls = { mason = false },
				nil_ls = { mason = false },
			},
		},
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				python = vim.fn.executable("ruff") == 1 and { "ruff_format" } or {},
				rust = vim.fn.executable("rustfmt") == 1 and { "rustfmt" } or {},
				c = vim.fn.executable("clang-format") == 1 and { "clang_format" } or {},
				cpp = vim.fn.executable("clang-format") == 1 and { "clang_format" } or {},
				nix = { "nixfmt" },
			},
		},
	},
	{ "folke/snacks.nvim", opts = { image = { enabled = false } } },
}
