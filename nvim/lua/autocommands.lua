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
	pattern = "*.gohtml,*.gotmpl,*.tmpl",
	callback = function()
		if vim.fn.search("{{.\\+}}", "nw") ~= 0 then
			local buf = vim.api.nvim_get_current_buf()
			vim.api.nvim_set_option_value("filetype", "gotmpl", { buf = buf })
			vim.api.nvim_set_option_value("filetype", "html", { buf = buf })
		end
	end,
})

-- Templ configuration
local templ_format = function()
	local bufnr = vim.api.nvim_get_current_buf()
	local filename = vim.api.nvim_buf_get_name(bufnr)
	local cmd = "templ fmt " .. vim.fn.shellescape(filename)

	vim.fn.jobstart(cmd, {
		on_exit = function()
			-- Reload the buffer only if it's still the current buffer
			if vim.api.nvim_get_current_buf() == bufnr then
				vim.cmd("e!")
			end
		end,
	})
end

vim.api.nvim_create_autocmd({ "BufWritePre" }, { pattern = { "*.templ" }, callback = templ_format })

-- Organize Golang imports on save
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = { "*.go" },
	callback = function(args)
		-- Disable 'No code actions available' message on write
		local original = vim.notify
		---@diagnostic disable-next-line: duplicate-set-field
		vim.notify = function(msg, level, opts)
			if msg == "No code actions available" then
				return
			end
			original(msg, level, opts)
		end

		vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
		vim.lsp.buf.code_action({ context = { only = { "source.fixAll" } }, apply = true })
		vim.lsp.buf.format()
	end,
})
