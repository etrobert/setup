--!nonstrict
-- Usage of the tank ZFS pool. The built-in sysmon disk widget measures with
-- statvfs, which on ZFS only sees a single dataset — zpool reports the whole
-- pool. Hidden on hosts without zpool (the bar config is shared).

local available = noctalia.commandExists("zpool")

if not available then
  barWidget.setVisible(false)
end

-- Pool usage moves slowly; a minute of lag is imperceptible.
noctalia.setUpdateInterval(60000)

function update()
  if not available then
    return
  end

  noctalia.runAsync("zpool list -H -o capacity,alloc,size tank", function(result)
    if result.exitCode ~= 0 then
      barWidget.setVisible(false)
      return
    end

    local capacity, alloc, size = string.match(result.stdout, "(%S+)%s+(%S+)%s+(%S+)")

    if capacity == nil then
      return
    end

    barWidget.setText(capacity)
    barWidget.setTooltip("tank " .. alloc .. " / " .. size)
  end, 5000)
end

update()
