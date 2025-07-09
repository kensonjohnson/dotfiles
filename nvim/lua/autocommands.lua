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
	local templ_cmd = "templ fmt " .. vim.fn.shellescape(filename)

	vim.fn.jobstart(templ_cmd, {
		on_exit = function()
			-- Run rustywind after templ fmt completes
			local rustywind_cmd = "rustywind --write " .. vim.fn.shellescape(filename)
			vim.fn.jobstart(rustywind_cmd, {
				on_exit = function()
					-- Reload the buffer only if it's still the current buffer
					if vim.api.nvim_get_current_buf() == bufnr then
						vim.cmd("e!")
					end
				end,
			})
		end,
	})
end

vim.api.nvim_create_autocmd({ "BufWritePre" }, { pattern = { "*.templ" }, callback = templ_format })

-- Organize Golang imports on save
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = { "*.go" },
	callback = function()
		-- Disable 'No code actions available' message on write
		local original = vim.notify
		---@diagnostic disable-next-line: duplicate-set-field
		vim.notify = function(msg, level, opts)
			if msg == "No code actions available" then
				return
			end
			original(msg, level, opts)
		end

		vim.lsp.buf.format()
		vim.lsp.buf.code_action({ context = { diagnostics = {}, only = { "source.organizeImports" } }, apply = true })
		vim.lsp.buf.code_action({ context = { diagnostics = {}, only = { "source.fixAll" } }, apply = true })
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function(args)
		vim.lsp.start({
			name = "iwes",
			cmd = { "iwes" },
			root_dir = vim.fs.root(args.buf, { ".iwe" }),
			flags = {
				debounce_text_changes = 500,
				exit_timeout = false,
			},
		})
	end,
})
