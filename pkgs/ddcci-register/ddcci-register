# Register DDC/CI external monitors as /sys/class/backlight devices so
# brightnessctl (and brightness-control) can drive them like a laptop panel.
#
# The ddcci kernel driver cannot auto-probe on kernel 6.8+, so the device must
# be instantiated by hand on each I2C bus that has a responsive monitor. This
# runs at boot and on every DRM hotplug (monitor connected or powered on), so a
# monitor that was off at boot still gets registered when it comes up.
#
# Idempotent: already-bound buses are left alone, and a stale device from an
# earlier failed probe is removed before retrying.

register_bus() {
  local bus=$1
  local dev="/sys/bus/i2c/devices/${bus}-0037"

  if [ -L "$dev/driver" ]; then
    return 0 # already bound to the ddcci driver — nothing to do
  fi
  if [ -e "$dev" ]; then
    # leftover from a probe that failed (e.g. monitor was off) — clear it first
    echo 0x37 >"/sys/bus/i2c/devices/i2c-${bus}/delete_device"
  fi
  echo "ddcci 0x37" >"/sys/bus/i2c/devices/i2c-${bus}/new_device"
}

# `ddcutil detect` lists only monitors that answered DDC/CI, and reports the
# real I2C bus regardless of GPU vendor (AMD, Intel, …). A monitor may need a
# moment to respond after a hotplug, so retry briefly before giving up.
buses=""
for _ in $(seq 1 5); do
  buses=$(ddcutil detect --terse |
    grep --only-matching '/dev/i2c-[0-9]\+' |
    grep --only-matching '[0-9]\+$' || true)
  if [ -n "$buses" ]; then
    break
  fi
  sleep 1
done

# Word-splitting on the newline-separated bus list is intentional.
# shellcheck disable=SC2086
for bus in $buses; do
  register_bus "$bus"
done
