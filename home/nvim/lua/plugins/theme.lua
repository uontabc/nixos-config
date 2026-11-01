return {
	{
		dir = "@catppuccin@",
		name = "catppuccin",
		lazy = false,
		priority = 1000,
		opts = {
			flavour = "mocha",
			transparent_background = false,
			color_overrides = { mocha = vim.json.decode([=[@palette@]=]) },
		},
	},
	{ "LazyVim/LazyVim", opts = { colorscheme = "catppuccin-mocha" } },
}
