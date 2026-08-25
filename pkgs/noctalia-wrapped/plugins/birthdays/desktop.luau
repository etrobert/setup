--!nonstrict
-- Upcoming birthdays, one line per person, as printed by the `birthdays`
-- script (pkgs/birthdays). A plugin because the built-in label widget renders
-- static text only; [lockscreen_widgets] in config.toml places it.

local FONT_SIZE = 22

-- The list only turns over at midnight, so a minute of lag is imperceptible.
noctalia.setUpdateInterval(60000)

local rows = {}

local function render()
	desktopWidget.render(ui.column({ gap = 6, align = "center" }, rows))
end

function update()
	noctalia.runAsync("birthdays", function(result)
		rows = {}

		for line in string.gmatch(result.stdout, "[^\n]+") do
			table.insert(
				rows,
				ui.label({ text = line, fontSize = FONT_SIZE, fontWeight = "bold", color = "on_surface" })
			)
		end

		render()
	end, 5000)
end

render()
update()
