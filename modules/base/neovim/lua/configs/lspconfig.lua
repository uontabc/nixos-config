vim.diagnostic.config({
	severity_sort = true,
	virtual_text = false,
	underline = true,
	update_in_insert = false,
	float = { border = "rounded", source = "if_many" },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "●",
			[vim.diagnostic.severity.WARN] = "▲",
			[vim.diagnostic.severity.INFO] = "■",
			[vim.diagnostic.severity.HINT] = "◆",
		},
	},
})

vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })
vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			diagnostics = { globals = { "vim", "Snacks" } },
			workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
			telemetry = { enable = false },
		},
	},
})
vim.lsp.config("nil_ls", { settings = { ["nil"] = { formatting = { command = { "nixfmt" } } } } })
vim.lsp.config("clangd", {
	cmd = {
		"clangd",
		"--background-index",
		"--clang-tidy",
		"--query-driver=/nix/store/*-gcc-wrapper-*/bin/*,/nix/store/*-clang-wrapper-*/bin/*,/run/current-system/sw/bin/*",
	},
})

local group = vim.api.nvim_create_augroup("user_lsp", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
	group = group,
	callback = function(event)
		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if client and client.name == "ruff" then
			client.server_capabilities.hoverProvider = false -- Use Pyright's documentation.
		end
		local function map(mode, key, action, desc)
			vim.keymap.set(mode, key, action, { buffer = event.buf, desc = desc })
		end
		map("n", "gd", Snacks.picker.lsp_definitions, "跳到定义")
		map("n", "gD", vim.lsp.buf.declaration, "跳到声明")
		map("n", "gr", Snacks.picker.lsp_references, "查找引用")
		map("n", "gI", Snacks.picker.lsp_implementations, "跳到实现")
		map("n", "gy", Snacks.picker.lsp_type_definitions, "跳到类型定义")
		map("n", "K", vim.lsp.buf.hover, "悬浮文档")
		map("n", "<F2>", vim.lsp.buf.rename, "重命名符号")
		map("n", "<leader>cr", vim.lsp.buf.rename, "Rename · 重命名符号")
		map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Action · 代码操作")
		map("n", "<leader>ck", vim.lsp.buf.signature_help, "查看函数签名")
		map("n", "<leader>cs", Snacks.picker.lsp_symbols, "当前文件符号")
		map("n", "<leader>cS", Snacks.picker.lsp_workspace_symbols, "工作区符号")
	end,
})

-- Nix supplies Lua/Nix tools. Other servers are enabled only inside dev shells
-- (or when installed on PATH); no Mason and no automatic executable downloads.
local servers = {
	lua_ls = "lua-language-server",
	nil_ls = "nil",
	clangd = "clangd",
	pyright = "pyright-langserver",
	ruff = "ruff",
	rust_analyzer = "rust-analyzer",
	gopls = "gopls",
	ts_ls = "typescript-language-server",
	bashls = "bash-language-server",
}
for server, executable in pairs(servers) do
	if vim.fn.executable(executable) == 1 then
		vim.lsp.enable(server)
	end
end
