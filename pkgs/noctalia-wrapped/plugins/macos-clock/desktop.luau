--!nonstrict
-- The date over a large, thin time, as the macOS lock screen shows it. A
-- plugin because the built-in clock widget draws a single line at a hardcoded
-- bold weight; [lockscreen_widgets] in config.toml places it.

local FONT_FAMILY = "Inter"
local DATE_FONT_SIZE = 34
local TIME_FONT_SIZE = 190

-- Second ticks so the minute turns over on time; the render below is skipped
-- on the 59 ticks that show the same thing.
noctalia.setUpdateInterval(1000)

local shown = ""

function update()
  local time = noctalia.formatTime("%H:%M")

  if time == shown then
    return
  end

  shown = time

  desktopWidget.render(ui.column({ gap = 4, align = "center" }, {
    ui.label({
      text = noctalia.formatTime("%A, %-d %B"),
      fontFamily = FONT_FAMILY,
      fontSize = DATE_FONT_SIZE,
      fontWeight = "medium",
      color = "on_surface",
    }),
    ui.label({
      text = time,
      fontFamily = FONT_FAMILY,
      fontSize = TIME_FONT_SIZE,
      fontWeight = "light",
      color = "on_surface",
    }),
  }))
end

update()
