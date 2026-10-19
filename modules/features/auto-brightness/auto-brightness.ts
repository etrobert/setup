import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import SunCalc from "suncalc";
import { $ } from "zx/core";
import * as z from "zod";

const PercentSchema = z.coerce.number().int().min(0).max(100);
const [day, night] = z
  .tuple([PercentSchema, PercentSchema])
  .parse(process.argv.slice(2));

// darkman caches the last location geoclue reported
const LocationSchema = z.object({ lat: z.number(), lng: z.number() });
const { lat, lng } = LocationSchema.parse(
  JSON.parse(
    await readFile(`${homedir()}/.cache/darkman/location.json`, "utf8"),
  ),
);

const { altitude } = SunCalc.getPosition(new Date(), lat, lng);
const elevation = (altitude * 180) / Math.PI;

// Day above 6°, night below -6° (end of civil twilight)
const fade = Math.min(Math.max((6 - elevation) / 12, 0), 1);

const brightness = Math.round(day - (day - night) * fade);
await $`noctalia msg brightness-set all ${brightness}%`;
