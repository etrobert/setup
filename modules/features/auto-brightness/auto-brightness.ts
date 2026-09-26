import { $ } from "bun";

const [day, night] = Bun.argv.slice(2).map(Number);
if (!Number.isInteger(day) || !Number.isInteger(night))
  throw new Error("usage: auto-brightness <day-percent> <night-percent>");

// Same curve as circadian_lighting in home-assistant.nix
const now = new Date();
const hour = now.getHours() + now.getMinutes() / 60;
const fade = hour < 5 ? 1 : Math.min(Math.max((hour - 16) / 7, 0), 1);

await $`noctalia msg brightness-set all ${Math.round(day - (day - night) * fade)}%`;
