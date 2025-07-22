return {
	"rebelot/kanagawa.nvim",
	priority = 1000,
	init = function()
		vim.cmd.colorscheme("kanagawa-dragon")
		--- Change spellchecker underline color
		vim.api.nvim_set_hl(0, "SpellBad", { undercurl = true, sp = "CornflowerBlue" })
		vim.api.nvim_set_hl(0, "SpellCap", { undercurl = true, sp = "CornflowerBlue" })
		vim.api.nvim_set_hl(0, "SpellRare", { undercurl = true, sp = "CornflowerBlue" })
		vim.api.nvim_set_hl(0, "SpellLocal", { undercurl = true, sp = "CornflowerBlue" })
	end,
}
