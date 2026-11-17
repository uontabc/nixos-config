if vim.fn.has("nvim-0.12") == 0 then
	error("This configuration requires Neovim 0.12+ (vim.pack).")
end

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("options")

-- Parsers are prebuilt by Nix. No :TSInstall, compiler or network access needed.
vim.opt.runtimepath:prepend("@treesitter@")
vim.opt.runtimepath:prepend("@treesitter_runtime@")

-- Seed a writable lock once. Rebuilds never overwrite locally reviewed updates.
local lock = vim.fn.stdpath("config") .. "/nvim-pack-lock.json"
if not vim.uv.fs_stat(lock) then
	vim.fn.mkdir(vim.fn.stdpath("config"), "p")
	vim.fn.writefile(vim.fn.readfile("@pack_lock@"), lock)
end

require("plugins")
require("configs.lspconfig")
require("autocmds")
require("mappings")
