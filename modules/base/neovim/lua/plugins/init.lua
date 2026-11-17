-- All plugins are ordinary Git checkouts managed by Neovim itself.
vim.pack.add({
	{ src = "https://github.com/nvim-mini/mini.nvim", version = "stable" },
	{ src = "https://github.com/folke/snacks.nvim" },
	{ src = "https://github.com/folke/which-key.nvim" },
	{ src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1") },
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
	{ src = "https://github.com/stevearc/conform.nvim" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/folke/tokyonight.nvim" },
}, { confirm = false })

require("tokyonight").setup({ style = "night", styles = { comments = { italic = false } } })
vim.cmd.colorscheme("tokyonight")

require("mini.icons").setup()
require("mini.icons").mock_nvim_web_devicons()
require("mini.statusline").setup()
require("mini.pairs").setup()
require("mini.surround").setup({
	-- Keep s/S (substitute) and ordinary Vim motions intact.
	mappings = {
		add = "gsa",
		delete = "gsd",
		find = "gsf",
		find_left = "gsF",
		highlight = "gsh",
		replace = "gsr",
		update_n_lines = "gsn",
	},
})

require("snacks").setup({
	dashboard = {
		enabled = true,
		width = 60,
		preset = {
			keys = {
				{ icon = " ", key = "f", desc = "查找文件", action = ":lua Snacks.picker.files()" },
				{ icon = " ", key = "n", desc = "新建文件", action = ":ene | startinsert" },
				{ icon = " ", key = "g", desc = "搜索文本", action = ":lua Snacks.picker.grep()" },
				{ icon = " ", key = "r", desc = "最近文件", action = ":lua Snacks.picker.recent()" },
				{
					icon = " ",
					key = "c",
					desc = "编辑配置",
					action = function()
						-- Edit the writable Nix source, not generated ~/.config links.
						Snacks.picker.files({ cwd = vim.env.HOME .. "/nixos-config/modules/base/neovim" })
					end,
				},
				{ icon = " ", key = "q", desc = "退出", action = ":confirm qall" },
			},
		},
		sections = {
			{ section = "header", padding = 1 },
			{ text = "写代码，也留一点审美。", align = "center", hl = "Comment", padding = 1 },
			{ section = "keys", indent = 3, gap = 0, padding = 1 },
			{ icon = " ", title = "最近打开", section = "recent_files", limit = 3, indent = 3, padding = 1 },
			function()
				local v = vim.version()
				return {
					footer = ("Neovim %d.%d.%d  ·  vim.pack  ·  Space ? 快捷键"):format(v.major, v.minor, v.patch),
				}
			end,
		},
	},
	bigfile = { enabled = true },
	quickfile = { enabled = true },
	explorer = { enabled = true },
	picker = {
		enabled = true,
		sources = {
			files = { hidden = true, exclude = { ".git" } },
			grep = { hidden = true, exclude = { ".git" } },
			explorer = { hidden = true },
		},
		win = {
			input = {
				keys = {
					["<Esc>"] = { "close", mode = { "i", "n" } },
					["<C-j>"] = { "list_down", mode = { "i", "n" } },
					["<C-k>"] = { "list_up", mode = { "i", "n" } },
				},
			},
		},
	},
	input = { enabled = true },
	terminal = { win = { position = "bottom", height = 0.3 } },
	-- Keep the dashboard static; no notification replacement or animated UI.
})

require("which-key").setup({ preset = "modern", delay = 350 })
require("which-key").add({
	{ "<leader>b", group = "Buffer · 缓冲区" },
	{ "<leader>c", group = "Code · 代码" },
	{ "<leader>f", group = "Find · 查找 / 文件" },
	{ "<leader>g", group = "Git · 版本管理" },
	{ "<leader>p", group = "Plugins · 插件" },
	{ "<leader>q", group = "Quit · 退出" },
	{ "<leader>t", group = "Terminal · 终端" },
	{ "<leader>u", group = "UI · 开关" },
	{ "<leader>w", group = "Window · 窗口" },
	{ "<leader>x", group = "Diagnostics · 诊断" },
	{ "gs", group = "Surround · 包围符", mode = { "n", "x" } },
})

require("blink.cmp").setup({
	-- Pure Lua avoids runtime binary downloads / builds on NixOS.
	fuzzy = { implementation = "lua" },
	keymap = {
		preset = "enter",
		["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
		["<C-n>"] = { "select_next", "fallback" },
		["<C-p>"] = { "select_prev", "fallback" },
		["<C-k>"] = false, -- Keep Vim's insert-mode digraph input.
	},
	completion = {
		list = { selection = { preselect = false, auto_insert = false } },
		menu = { border = "rounded" },
		documentation = { auto_show = true, auto_show_delay_ms = 250, window = { border = "rounded" } },
	},
	signature = { enabled = true, window = { border = "rounded" } },
	sources = { default = { "lsp", "path", "snippets", "buffer" } },
	cmdline = { enabled = false }, -- Leave :, / and ? completion to Neovim.
})

require("gitsigns").setup({
	signs = {
		add = { text = "│" },
		change = { text = "│" },
		delete = { text = "_" },
		topdelete = { text = "‾" },
		changedelete = { text = "~" },
	},
	current_line_blame = false,
	on_attach = function(buf)
		local gs = require("gitsigns")
		local function map(key, action, desc)
			vim.keymap.set("n", key, action, { buffer = buf, desc = desc })
		end
		map("]h", function()
			gs.nav_hunk("next")
		end, "下一个 Git 改动")
		map("[h", function()
			gs.nav_hunk("prev")
		end, "上一个 Git 改动")
		map("<leader>gh", gs.preview_hunk, "预览当前改动")
		map("<leader>gs", gs.stage_hunk, "暂存 / 取消暂存当前改动")
		map("<leader>gB", gs.blame_line, "查看当前行提交信息")
		map("<leader>gd", gs.diffthis, "与 Git 索引对比")
	end,
})

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		nix = { "nixfmt" },
		python = { "ruff_format" },
		rust = { "rustfmt" },
		c = { "clang_format" },
		cpp = { "clang_format" },
		go = { "gofmt" },
		javascript = { "prettier" },
		typescript = { "prettier" },
		javascriptreact = { "prettier" },
		typescriptreact = { "prettier" },
		json = { "prettier" },
		yaml = { "prettier" },
		markdown = { "prettier" },
	},
	default_format_opts = { lsp_format = "fallback" },
	-- Opt in per buffer with Space uf. Saving alone never rewrites your code.
	format_on_save = function(buf)
		if vim.b[buf].autoformat then
			return { timeout_ms = 1500, lsp_format = "fallback" }
		end
	end,
})

vim.api.nvim_create_user_command("PackUpdate", function()
	vim.pack.update()
end, { desc = "审阅插件更新；:write 确认，:quit 取消" })
vim.api.nvim_create_user_command("PackInfo", function()
	vim.pack.update(nil, { offline = true })
end, { desc = "离线查看插件版本和状态" })
