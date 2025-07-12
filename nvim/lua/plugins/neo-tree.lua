return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
		"MunifTanjim/nui.nvim",
		"folke/snacks.nvim", -- For image support
	},
	lazy = false, -- neo-tree will lazily load itself
	---@module "neo-tree"
	---@type neotree.Config?
	opts = {
		filesystem = {
			window = {
				mappings = {
					["\\"] = "close_window",
				},
			},
			components = {
				harpoon_index = function(config, node, _)
					local harpoon_list = require("harpoon"):list()
					local path = node:get_id()
					local harpoon_key = vim.uv.cwd()

					for i, item in ipairs(harpoon_list.items) do
						local value = item.value
						if string.sub(item.value, 1, 1) ~= "/" then
							value = harpoon_key .. "/" .. item.value
						end

						if value == path then
							vim.print(path)
							return {
								text = string.format("  %d", i),
								highlight = config.highlight or "NeoTreeDirectoryIcon",
							}
						end
					end
					return {}
				end,
			},
			renderers = {
				file = {
					{ "icon" },
					{ "name", use_git_status_colors = true },
					{ "harpoon_index" },
					{ "diagnostics" },
					{ "git_status", highlight = "NeoTreeDimText" },
				},
			},
		},
		event_handlers = {
			{
				event = "file_opened",
				handler = function()
					require("neo-tree.command").execute({ action = "close" })
				end,
			},
		},
	},
	keys = {
		{ "\\", ":Neotree reveal<CR>", desc = "NeoTree reveal", silent = true },
	},
}
