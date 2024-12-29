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

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "*.gohtml,*.gotmpl,*.html,*tmpl",
	callback = function()
		if vim.fn.search("{{.\\+}}", "nw") ~= 0 then
			local buf = vim.api.nvim_get_current_buf()
			vim.api.nvim_buf_set_option(buf, "filetype", "gotmpl")
			vim.api.nvim_buf_set_option(buf, "filetype", "html")
		end
	end,
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, { pattern = { "*.templ" }, callback = vim.lsp.buf.format })
