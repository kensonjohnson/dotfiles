----------------------------------------------------------------------
---- Needed Imports --------------------------------------------------
----------------------------------------------------------------------
---
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

--- This repeats a node
--- rep(<position>)
local rep = require("luasnip.extras").rep

----------------------------------------------------------------------
---- Define Snippets -------------------------------------------------
----------------------------------------------------------------------

luasnip.add_snippets("lua", {
	luasnip.parser.parse_snippet("lf", "local $1 = function($2)\n  $0\nend"),
	snippet("req", format("local {} = require('{}')", { insert(1, "default"), rep(1) })),
})
