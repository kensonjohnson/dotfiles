--- Create global group
local buf_check = vim.api.nvim_create_augroup("YankHighlight", { clear = true })

--- Disable spellchecker in terminal
vim.api.nvim_create_autocmd("TermOpen", {
	group = buf_check,
	pattern = "*",
	command = "setlocal nospell",
})

--- Start terminal in insert mode
vim.api.nvim_create_autocmd("TermOpen", {
	group = buf_check,
	pattern = "*",
	command = "startinsert | set winfixheight",
})

--- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = buf_check,
	pattern = "*",
})
