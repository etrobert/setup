--!nonstrict
-- A click to pause or resume auto-brightness
-- (modules/features/auto-brightness/default.nix).

-- %S/auto-brightness-paused in the user service.
local PAUSED = noctalia.expandPath("~/.local/state/auto-brightness-paused")

noctalia.setUpdateInterval(1000)

function update()
	if noctalia.fileExists(PAUSED) then
		barWidget.setGlyph("brightness-off")
		barWidget.setTooltip("Auto-brightness paused")
	else
		barWidget.setGlyph("brightness-auto")
		barWidget.setTooltip("Auto-brightness on")
	end
end

local function run(argv, andThen)
	noctalia.runAsync(argv, function(result)
		if result.exitCode ~= 0 then
			noctalia.notifyError("Auto-brightness toggle failed", result.stderr)
		elseif andThen then
			andThen()
		end
		update()
	end)
end

function onClick()
	if noctalia.fileExists(PAUSED) then
		-- Apply the current brightness rather than wait up to 15 minutes for the timer.
		run({ "rm", PAUSED }, function()
			run({ "systemctl", "--user", "start", "auto-brightness.service" })
		end)
	else
		run({ "touch", PAUSED })
	end
end

update()
