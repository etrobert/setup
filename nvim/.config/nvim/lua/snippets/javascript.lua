local luasnip = require("luasnip")
local snippet = luasnip.snippet
local text_node = luasnip.text_node
local insert_node = luasnip.insert_node
local rep = require("luasnip.extras").rep

return {
	snippet("uel", {
		text_node("useEffect(() => {"),
		text_node({ "", "  console.log('" }),
		insert_node(1, "variable"),
		text_node(" changed:', "),
		rep(1),
		text_node(");"),
		text_node({ "", "}, [" }),
		rep(1),
		text_node("]);"),
	}),
}
