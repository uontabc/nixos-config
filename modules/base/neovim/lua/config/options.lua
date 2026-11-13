vim.g.uontabc_treesitter_runtime = "@treesitter_runtime@"
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.lazyvim_python_lsp = "pyright"
vim.g.lazyvim_python_ruff = "ruff"
vim.g.lazyvim_rust_diagnostics = "rust-analyzer"

vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.clipboard = "unnamedplus"
vim.opt.scrolloff = 8
vim.opt.wrap = false

-- Windows clipboard integration, without injecting Windows programs into Nix.
if vim.fn.executable("/mnt/c/Windows/System32/clip.exe") == 1 then
	vim.g.clipboard = {
		name = "Windows",
		copy = {
			["+"] = { "/mnt/c/Windows/System32/clip.exe" },
			["*"] = { "/mnt/c/Windows/System32/clip.exe" },
		},
		paste = {
			["+"] = {
				"/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe",
				"-NoProfile",
				"-Command",
				"Get-Clipboard -Raw",
			},
			["*"] = {
				"/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe",
				"-NoProfile",
				"-Command",
				"Get-Clipboard -Raw",
			},
		},
		cache_enabled = 0,
	}
end
