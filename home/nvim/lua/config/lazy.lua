-- Both the plugin manager and LazyVim itself are pinned in flake.lock.
vim.opt.rtp:prepend("@lazy_nvim@")
vim.opt.rtp:prepend("@lazyvim@")

require("lazy").setup({
	spec = {
		-- Register the local package separately: an import's name changes the
		-- identifier in lazy.nvim's import list and breaks LazyVim's order check.
		{ dir = "@lazyvim@", name = "LazyVim" },
		{ import = "lazyvim.plugins" },
		{ import = "lazyvim.plugins.extras.lang.python" },
		{ import = "lazyvim.plugins.extras.lang.rust" },
		{ import = "lazyvim.plugins.extras.lang.clangd" },
		{ import = "plugins" },
	},
	defaults = { lazy = false, version = false },
	-- Hjem links config files into the store; writable state stays under XDG state.
	lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
	install = { colorscheme = { "catppuccin-mocha", "habamax" } },
	checker = { enabled = false },
	change_detection = { notify = false },
})
