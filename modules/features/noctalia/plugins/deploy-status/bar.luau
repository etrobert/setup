--!nonstrict
-- Whether this host runs setup's deploy branch, and a click to pause or
-- resume auto-upgrade (modules/features/auto-upgrade.nix).

local PAUSED = "/var/lib/nixos-upgrade/paused"
local DEPLOY_URL = "https://github.com/etrobert/setup.git"

-- Matches the upgrade timer, so the bar turns green about when the switch lands.
noctalia.setUpdateInterval(60000)

local function short(rev)
	return rev and string.sub(rev, 1, 8) or "unknown"
end

local function render(running, deploy)
	local paused = noctalia.fileExists(PAUSED)
	local tooltip = {
		{ "Running", short(running) },
		{ "Deploy", short(deploy) },
		{ "Auto-upgrade", paused and "paused" or "on" },
	}
	barWidget.setTooltip(tooltip)

	if paused then
		barWidget.setGlyph("player-pause")
		barWidget.setGlyphColor("on_surface")
	elseif not running or not deploy then
		barWidget.setGlyph("cloud-question")
		barWidget.setGlyphColor("on_surface")
	elseif running == deploy then
		barWidget.setGlyph("circle-check")
		barWidget.setGlyphColor("on_surface")
	else
		barWidget.setGlyph("refresh")
		barWidget.setGlyphColor("error")
	end
end

function update()
	noctalia.runAsync({ "nixos-version", "--configuration-revision" }, function(version)
		local running = version.exitCode == 0 and noctalia.string.trim(version.stdout) or nil
		noctalia.runAsync({ "git", "ls-remote", DEPLOY_URL, "refs/heads/deploy" }, function(remote)
			local deploy = remote.exitCode == 0 and string.match(remote.stdout, "^(%x+)") or nil
			render(running, deploy)
		end)
	end)
end

function onClick()
	local argv
	if noctalia.fileExists(PAUSED) then
		argv = { "sudo", "--non-interactive", "rm", PAUSED }
	else
		argv = { "sudo", "--non-interactive", "touch", PAUSED }
	end
	noctalia.runAsync(argv, function(result)
		if result.exitCode ~= 0 then
			noctalia.notifyError("Auto-upgrade toggle failed", result.stderr)
		end
		update()
	end)
end

update()
