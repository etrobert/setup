--!nonstrict
-- Busy time of the disks backing the tank pool: the share of the last interval
-- each disk spent with at least one request in flight, taken as the max across
-- the vdev members because a raidz read waits on every column.
--
-- This is not a saturation gauge. A queued SSD reads 100% busy well before it
-- runs out of throughput, and tank's members reach 80% at a few kB/s once their
-- latency degrades — so the tooltip carries await, which is what distinguishes
-- busy from stalled.
--
-- The built-in sysmon disk widget measures capacity with statvfs and has no IO
-- counterpart. Hidden on hosts without the pool, since the bar config is shared.

local members = {}
local previous = nil

-- Fast enough to show a burst, slow enough that the io_ticks delta is not
-- dominated by the kernel's millisecond accounting.
noctalia.setUpdateInterval(2000)

barWidget.setVisible(false)
barWidget.setGlyph("activity")

-- -L resolves the by-id paths the pool was created with down to kernel names,
-- which is how /proc/diskstats is keyed. Any token naming a block device is a
-- leaf vdev, so membership falls out without parsing the tree's indentation.
noctalia.runAsync("zpool status -L tank", function(result)
  if result.exitCode ~= 0 then
    return
  end

  for token in string.gmatch(result.stdout, "%S+") do
    if noctalia.fileExists("/sys/class/block/" .. token) then
      members[token] = true
    end
  end
end, 5000)

local function sample()
  local diskstats = noctalia.readFile("/proc/diskstats")

  if diskstats == nil then
    return nil
  end

  local disks = {}

  for line in string.gmatch(diskstats, "[^\n]+") do
    local fields = {}

    for field in string.gmatch(line, "%S+") do
      table.insert(fields, field)
    end

    -- Kernel-documented field order, offset by the leading major/minor/name:
    -- 4 reads, 7 ms reading, 8 writes, 11 ms writing, 13 ms doing IO.
    if members[fields[3]] then
      disks[fields[3]] = {
        busyMs = tonumber(fields[13]),
        ops = tonumber(fields[4]) + tonumber(fields[8]),
        waitMs = tonumber(fields[7]) + tonumber(fields[11]),
      }
    end
  end

  return { atMs = noctalia.nowMs(), disks = disks }
end

function update()
  local current = sample()

  if current == nil then
    return
  end

  local last = previous
  previous = current

  if last == nil then
    return
  end

  local elapsedMs = current.atMs - last.atMs

  if elapsedMs <= 0 then
    return
  end

  local busiest = 0
  local rows = {}

  for name, disk in pairs(current.disks) do
    local before = last.disks[name]

    if before ~= nil then
      local busy = math.min(100, (disk.busyMs - before.busyMs) / elapsedMs * 100)
      local ops = disk.ops - before.ops
      local await = 0

      if ops > 0 then
        await = (disk.waitMs - before.waitMs) / ops
      end

      busiest = math.max(busiest, busy)
      table.insert(rows, string.format("%s  %3.0f%%  %6.1f ms", name, busy, await))
    end
  end

  if #rows == 0 then
    return
  end

  -- pairs() has no order; the tooltip should not reshuffle every tick.
  table.sort(rows)

  barWidget.setVisible(true)
  barWidget.setText(string.format("%.0f", busiest))
  barWidget.setTooltip("tank busy / await\n" .. table.concat(rows, "\n"))
end

update()
