#!/usr/bin/env node
import { execFileSync } from "node:child_process";
import SunCalc from "suncalc";

const [day, night] = process.argv.slice(2).map(Number);
if (!Number.isInteger(day) || !Number.isInteger(night))
  throw new Error("usage: auto-brightness <day-percent> <night-percent>");

// Berlin, as in darkman.nix
const { altitude } = SunCalc.getPosition(new Date(), 52.5, 13.4);
const elevation = (altitude * 180) / Math.PI;

// Day above 6°, night below -6° (end of civil twilight)
const fade = Math.min(Math.max((6 - elevation) / 12, 0), 1);

execFileSync(
  "noctalia",
  [
    "msg",
    "brightness-set",
    "all",
    `${Math.round(day - (day - night) * fade)}%`,
  ],
  {
    stdio: "inherit",
  },
);
