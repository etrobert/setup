--!nonstrict
-- Whether this host runs setup's deploy branch, and a click to pause or
-- resume auto-upgrade (modules/features/auto-upgrade.nix).

local PAUSED = "/var/lib/nixos-upgrade/paused"
local DEPLOY_URL = "https://github.com/etrobert/setup.git"
-- deploy only moves when CI pushes, so spare GitHub a request every second.
local DEPLOY_EVERY = 60

noctalia.setUpdateInterval(1000)

local deploy = nil
local deployCheckedAt = nil
local upgradedAt = nil

local function short(rev)
	return rev and string.sub(rev, 1, 8) or "unknown"
end

local function render(running, upgrading)
	local paused = noctalia.fileExists(PAUSED)
	local tooltip = {
		{ "Running", short(running) },
		{ "Deploy", short(deploy) },
		{ "Auto-upgrade", upgrading and "upgrading" or paused and "paused" or "on" },
		{ "Last upgrade", upgradedAt and noctalia.formatTime("%Y-%m-%d %H:%M", upgradedAt) or "unknown" },
	}
	barWidget.setTooltip(tooltip)

	if upgrading then
		barWidget.setGlyph("download")
		barWidget.setGlyphColor("on_surface")
	elseif paused then
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

local function fetchDeploy()
	deployCheckedAt = os.time()
	noctalia.runAsync({ "git", "ls-remote", DEPLOY_URL, "refs/heads/deploy" }, function(remote)
		deploy = remote.exitCode == 0 and string.match(remote.stdout, "^(%x+)") or nil
	end)
end

function update()
	if not deployCheckedAt or os.time() - deployCheckedAt >= DEPLOY_EVERY then
		fetchDeploy()
	end
	-- stat, not fileInfo: fileInfo follows the link to the store, where mtime is 1970.
	noctalia.runAsync({ "stat", "--format=%Y", "/nix/var/nix/profiles/system" }, function(profile)
		upgradedAt = profile.exitCode == 0 and tonumber(profile.stdout) or nil
	end)
	noctalia.runAsync({ "nixos-version", "--configuration-revision" }, function(version)
		local running = version.exitCode == 0 and noctalia.string.trim(version.stdout) or nil
		noctalia.runAsync(
			{ "systemctl", "show", "--property=SubState", "--value", "nixos-upgrade.service" },
			function(unit)
				-- "condition" is deploy-gate's sub-second check, not an upgrade.
				local state = noctalia.string.trim(unit.stdout)
				render(running, state == "start-pre" or state == "start" or state == "start-post")
			end
		)
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
