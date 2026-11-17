local function map(mode, key, action, desc, opts)
	vim.keymap.set(mode, key, action, vim.tbl_extend("force", { silent = true, desc = desc }, opts or {}))
end
local function n(key, action, desc)
	map("n", key, action, desc)
end

-- Familiar shortcuts without turning Vim into a different editor.
map({ "n", "i", "x", "s" }, "<C-s>", "<cmd>update<cr>", "保存文件")
n("<Esc>", "<cmd>nohlsearch<cr><Esc>", "取消搜索高亮")
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", "向下（兼容折行）", { expr = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", "向上（兼容折行）", { expr = true })
map("x", "<", "<gv", "减少缩进并保持选区")
map("x", ">", ">gv", "增加缩进并保持选区")

n("<leader><space>", Snacks.picker.files, "查找文件")
n("<C-p>", Snacks.picker.files, "查找文件")
n("<leader>/", Snacks.picker.grep, "搜索项目文本")
n("<leader>,", Snacks.picker.buffers, "切换缓冲区")
n("<leader>e", function()
	Snacks.explorer()
end, "打开 / 关闭文件侧栏")
n("<leader>?", Snacks.picker.keymaps, "搜索快捷键")
n("<leader>h", function()
	Snacks.dashboard()
end, "Home · 启动首页")
n("<leader>ff", Snacks.picker.files, "Files · 查找文件")
n("<leader>fg", Snacks.picker.grep, "Grep · 搜索项目文本")
map({ "n", "x" }, "<leader>fw", Snacks.picker.grep_word, "Word · 搜索光标词 / 选中文本")
n("<leader>fr", Snacks.picker.recent, "Recent · 最近文件")
n("<leader>fb", Snacks.picker.buffers, "Buffers · 缓冲区")
n("<leader>fh", Snacks.picker.help, "Help · 帮助文档")
n("<leader>fk", Snacks.picker.keymaps, "Keys · 快捷键")
n("<leader>fs", "<cmd>update<cr>", "Save · 保存文件")

n("]b", "<cmd>bnext<cr>", "下一个缓冲区")
n("[b", "<cmd>bprevious<cr>", "上一个缓冲区")
n("<leader>bb", Snacks.picker.buffers, "选择缓冲区")
n("<leader>bd", function()
	Snacks.bufdelete()
end, "关闭缓冲区（保留窗口）")
n("<leader>bo", function()
	Snacks.bufdelete.other()
end, "关闭其他缓冲区（未保存时询问）")

for key, direction in pairs({ h = "h", j = "j", k = "k", l = "l" }) do
	n("<C-" .. key .. ">", "<C-w>" .. direction, "切换到相邻窗口")
	n("<leader>w" .. key, "<C-w>" .. direction, "切换到相邻窗口")
end
n("<leader>wv", "<cmd>vsplit<cr>", "Vertical · 左右分屏")
n("<leader>ws", "<cmd>split<cr>", "Split · 上下分屏")
n("<leader>wc", "<cmd>confirm close<cr>", "Close · 关闭窗口")
n("<leader>wo", "<cmd>confirm only<cr>", "Only · 只保留当前窗口")
n("<leader>we", "<C-w>=", "Equal · 均分窗口")
n("<leader>qq", "<cmd>confirm qall<cr>", "退出 Neovim（未保存时询问）")

map({ "n", "x" }, "<leader>cf", function()
	require("conform").format({ async = true, lsp_format = "fallback" })
end, "Format · 格式化文件 / 选区")
n("<leader>cd", vim.diagnostic.open_float, "查看当前行诊断")
n("<leader>cl", "<cmd>checkhealth vim.lsp<cr>", "检查语言服务器状态")
n("<leader>xx", Snacks.picker.diagnostics, "工作区诊断")
n("<leader>xd", Snacks.picker.diagnostics_buffer, "当前文件诊断")
n("<leader>xq", Snacks.picker.qflist, "Quickfix 列表")
n("]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, "下一个诊断")
n("[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, "上一个诊断")

n("<leader>gg", Snacks.picker.git_status, "Git 工作区状态")
n("<leader>gl", Snacks.picker.git_log, "Git 提交历史")
n("<leader>gf", Snacks.picker.git_log_file, "当前文件提交历史")
n("<leader>gb", Snacks.picker.git_branches, "Git 分支（回车可切换）")

local function terminal()
	Snacks.terminal.toggle()
end
map({ "n", "t" }, "<C-/>", terminal, "打开 / 隐藏终端")
-- Many terminals send Ctrl+/ as Ctrl+_; keep the same action for both.
map({ "n", "t" }, "<C-_>", terminal, "打开 / 隐藏终端")
n("<leader>tt", terminal, "打开 / 隐藏终端")
-- Do not steal terminal Ctrl+h / Ctrl+l / Ctrl+c or a single Escape.
-- Snacks supports double Escape to leave terminal input; Ctrl+\ Ctrl+n also works.

n("<leader>uw", function()
	vim.wo.wrap = not vim.wo.wrap
	vim.notify("自动折行: " .. (vim.wo.wrap and "开启" or "关闭"))
end, "Wrap · 切换自动折行")
n("<leader>un", function()
	vim.wo.relativenumber = not vim.wo.relativenumber
end, "Number · 切换相对行号")
n("<leader>uf", function()
	vim.b.autoformat = not vim.b.autoformat
	vim.notify("当前文件保存时格式化: " .. (vim.b.autoformat and "开启" or "关闭"))
end, "Format · 切换当前文件自动格式化")
n("<leader>ud", function()
	vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, "Diagnostics · 切换诊断显示")
n("<leader>uh", function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
end, "Hints · 切换类型提示")

n("<leader>pu", "<cmd>PackUpdate<cr>", "Update · 审阅插件更新")
n("<leader>pi", "<cmd>PackInfo<cr>", "Info · 离线查看插件版本")
