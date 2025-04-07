----------------------------------------------------------------------
---- Needed Imports --------------------------------------------------
----------------------------------------------------------------------

local luasnip = require("luasnip")

--- This is a snippet creation function
--- s(<trigger>, <nodes>)
local snippet = luasnip.s

--- This is a format function
--- fmt(<fmt_string>, {...nodes})
local format = require("luasnip.extras.fmt").fmt

--- This is an insert node
--- It takes in a position (like $1) and optional text
--- insert_node(<position>, [default_text])
local insert = luasnip.insert_node

----------------------------------------------------------------------
---- Define Snippets -------------------------------------------------
----------------------------------------------------------------------

luasnip.add_snippets("go", {
	snippet("ien", format("if err != nil {{\n\t{}\n}}", { insert(1) })),
})
