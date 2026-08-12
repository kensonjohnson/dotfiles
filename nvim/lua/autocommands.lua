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

--- Apply gopls source actions before formatting so their edits are included in the save.
local function apply_go_code_actions(bufnr, only)
	for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = "gopls" })) do
		if client:supports_method("textDocument/codeAction", bufnr) then
			local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
			params.context = { diagnostics = {}, only = only }
			local response, err = client:request_sync("textDocument/codeAction", params, 2000, bufnr)

			if err or (response and response.err) then
				local message = err or response.err.message
				vim.notify("gopls code action failed: " .. message, vim.log.levels.WARN)
			elseif response then
				for _, action in ipairs(response.result or {}) do
					if not (action.edit or action.command) and client:supports_method("codeAction/resolve", bufnr) then
						local resolved, resolve_err = client:request_sync("codeAction/resolve", action, 2000, bufnr)
						if resolve_err or not resolved or resolved.err then
							local message = resolve_err or (resolved and resolved.err.message) or "unknown error"
							vim.notify("gopls code action resolution failed: " .. message, vim.log.levels.WARN)
							action = nil
						else
							action = resolved.result
						end
					end

					if action then
						if action.edit then
							vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
						end
						if action.command then
							local command = type(action.command) == "table" and action.command or action
							local result, command_err = client:request_sync("workspace/executeCommand", {
								command = command.command,
								arguments = command.arguments,
							}, 2000, bufnr)
							if command_err or (result and result.err) then
								local message = command_err or result.err.message
								vim.notify("gopls code action command failed: " .. message, vim.log.levels.WARN)
							end
						end
					end
				end
			end
		end
	end
end

local function format_go(bufnr)
	for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = "gopls" })) do
		if client:supports_method("textDocument/formatting", bufnr) then
			vim.lsp.buf.format({
				bufnr = bufnr,
				async = false,
				timeout_ms = 2000,
				filter = function(formatter)
					return formatter.id == client.id
				end,
			})
			return
		end
	end
end

--- Organize Golang imports, apply gopls fixes, then format synchronously on save.
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = { "*.go" },
	callback = function(args)
		apply_go_code_actions(args.buf, { "source.organizeImports" })
		apply_go_code_actions(args.buf, { "source.fixAll" })
		format_go(args.buf)
	end,
})
