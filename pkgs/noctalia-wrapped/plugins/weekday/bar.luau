--!nonstrict
-- Two-letter weekday, reproducing `date +%a | cut -c1-2` from the waybar module
-- this replaces.
--
-- The built-in clock widget cannot do it: its format string is handed straight
-- to strftime (src/time/time_format.cpp), which pads but never truncates, and
-- noctalia discards anything before the first % in the spec. Hence a plugin,
-- where the string is ours to slice.

-- The text only changes at midnight; a minute of lag is imperceptible and this
-- costs one strftime call per tick.
noctalia.setUpdateInterval(60000)

function update()
  barWidget.setText(string.sub(noctalia.formatTime("%a"), 1, 2))
  barWidget.setTooltip(noctalia.formatTime("%A"))
end

update()
