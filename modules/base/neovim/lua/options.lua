local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.laststatus = 3
opt.showmode = false
opt.mouse = "a"
opt.wrap = false
opt.breakindent = true
opt.scrolloff = 6
opt.sidescrolloff = 8
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen"
opt.winborder = "rounded"

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true
opt.inccommand = "split"
opt.completeopt = { "menu", "menuone", "noselect" }

opt.clipboard = "unnamedplus"
opt.undofile = true
opt.swapfile = true
opt.backup = false
opt.hidden = true
opt.confirm = true
opt.updatetime = 250
opt.timeoutlen = 500
opt.ttimeoutlen = 10
opt.shortmess:append("c")
opt.jumpoptions = "view"
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.fillchars = { eob = " " }
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldtext = ""

-- Windows clipboard integration when this configuration is used on WSL.
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
