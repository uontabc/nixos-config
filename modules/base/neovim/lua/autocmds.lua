local group = vim.api.nvim_create_augroup("user_editor", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
	group = group,
	callback = function()
		vim.hl.on_yank({ timeout = 150 })
	end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
	group = group,
	callback = function(event)
		-- Restore the last cursor position, but not in commit messages.
		vim.api.nvim_buf_call(event.buf, function()
			if vim.bo.filetype == "gitcommit" then
				return
			end
			local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
			if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(event.buf) then
				pcall(vim.api.nvim_win_set_cursor, 0, mark)
			end
		end)
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = group,
	callback = function(event)
		if vim.bo[event.buf].buftype ~= "" then
			return
		end
		-- Treesitter is optional per filetype; unsupported files keep syntax fallback.
		local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(event.buf))
		if size > 1024 * 1024 or vim.api.nvim_buf_line_count(event.buf) > 20000 then
			vim.opt_local.foldmethod = "manual"
			return
		end
		pcall(vim.treesitter.start, event.buf)
	end,
})

vim.api.nvim_create_autocmd("VimResized", {
	group = group,
	command = "wincmd =",
})

vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
	group = group,
	callback = function()
		if vim.fn.getcmdwintype() == "" then
			vim.cmd("checktime")
		end
	end,
})
