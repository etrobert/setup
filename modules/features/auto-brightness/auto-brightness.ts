import SunCalc from "suncalc";
import { $ } from "zx/core";
import * as z from "zod";

const PercentSchema = z.coerce.number().int().min(0).max(100);
const [day, night] = z
  .tuple([PercentSchema, PercentSchema])
  .parse(process.argv.slice(2));

// Berlin, as in darkman.nix
const { altitude } = SunCalc.getPosition(new Date(), 52.5, 13.4);
const elevation = (altitude * 180) / Math.PI;

// Day above 6°, night below -6° (end of civil twilight)
const fade = Math.min(Math.max((6 - elevation) / 12, 0), 1);

const brightness = Math.round(day - (day - night) * fade);
await $`noctalia msg brightness-set all ${brightness}%`;
