--!nonstrict

local WIDTH = 720
local PADDING = 20

local function render(text)
	layer.render(ui.row({
		width = WIDTH,
		padding = PADDING,
		gap = 14,
		align = "start",
		fill = "surface",
		radius = 18,
		border = "outline_variant",
		borderWidth = 1,
	}, {
		ui.glyph({ name = "microphone", size = 24, color = "primary" }),
		ui.label({ text = text, fontSize = 20, color = "on_surface", maxWidth = WIDTH - PADDING * 2 - 38 }),
	}))
end

noctalia.state.watch("text", render)
render(noctalia.state.get("text"))
