-- Both the plugin manager and LazyVim itself are pinned in flake.lock.
vim.opt.rtp:prepend("@lazy_nvim@")

require("lazy").setup({
	spec = {
		{ dir = "@lazyvim@", name = "LazyVim", import = "lazyvim.plugins" },
		{ import = "lazyvim.plugins.extras.lang.python" },
		{ import = "lazyvim.plugins.extras.lang.rust" },
		{ import = "lazyvim.plugins.extras.lang.clangd" },
		{ import = "plugins" },
	},
	defaults = { lazy = false, version = false },
	-- Hjem links config files into the store; writable state stays under XDG state.
	lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
	install = { colorscheme = { "tokyonight", "habamax" } },
	checker = { enabled = false },
	change_detection = { notify = false },
})
