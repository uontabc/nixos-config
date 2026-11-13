return {
	{ "catppuccin/nvim", enabled = false },
	{
		"folke/tokyonight.nvim",
		dir = "@tokyonight@",
		lazy = false,
		priority = 1000,
		opts = { style = "night", transparent = false },
	},
	{ "LazyVim/LazyVim", opts = { colorscheme = "tokyonight-night" } },
}
