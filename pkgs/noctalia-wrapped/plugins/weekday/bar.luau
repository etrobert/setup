--!nonstrict
-- Two-letter weekday.
--
-- The built-in clock widget cannot produce one: its format string is handed
-- straight to strftime, which pads but never truncates, and noctalia discards
-- anything before the first % in the spec. A plugin owns the string, so it can
-- slice it.

-- The text only changes at midnight; a minute of lag is imperceptible and this
-- costs one strftime call per tick.
noctalia.setUpdateInterval(60000)

function update()
  barWidget.setText(string.sub(noctalia.formatTime("%a"), 1, 2))
  barWidget.setTooltip(noctalia.formatTime("%A"))
end

update()
