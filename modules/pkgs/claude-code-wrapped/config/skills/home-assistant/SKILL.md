---
name: home-assistant
description:
  Read and control Étienne's Home Assistant on tower through `hass-cli`. Use
  whenever he asks about home sensors, air quality (AirGradient, CO2, PM2.5,
  VOC), temperature, humidity, devices, automations, or anything in Home
  Assistant.
---

# Home Assistant

Home Assistant runs on `tower:8123` (`modules/features/home-assistant.nix` in
`etrobert/setup`). `hass-cli` is on PATH with the server and token already set.

```sh
hass-cli state list 'sensor.i_9psl'
hass-cli --output json state history sensor.i_9psl_pm0_3 --since 3d
```

The recorder keeps about 10 days of history.

## AirGradient ONE (living room)

Entities are prefixed `sensor.i_9psl_*`. The recorder keeps more than the
dashboard shows — notably `sensor.i_9psl_pm0_3` (0.3 µm particle _count_, the
best fine-particle signal), `sensor.i_9psl_voc_index`, and
`sensor.i_9psl_nox_index`. The device's own local API
(`http://<ip>/measures/current`) returns only current values, no history.
