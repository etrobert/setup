import { $ } from "zx/core";
import * as z from "zod";

const PercentSchema = z.coerce.number().int().min(0).max(100);
const [day, night] = z
  .tuple([PercentSchema, PercentSchema])
  .parse(process.argv.slice(2));

// Same curve as circadian_lighting in home-assistant.nix
const now = new Date();
const hour = now.getHours() + now.getMinutes() / 60;
const fade = hour < 5 ? 1 : Math.min(Math.max((hour - 16) / 7, 0), 1);

const brightness = Math.round(day - (day - night) * fade);
await $`noctalia msg brightness-set all ${brightness}%`;
