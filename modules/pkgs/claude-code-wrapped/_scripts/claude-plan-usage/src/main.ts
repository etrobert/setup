import { $ } from "bun";
import { z } from "zod";

// The fields read from the statusline payload; every branch of `rate_limits`
// and `used_percentage` may be absent per the docs, nothing else is optional.
const Window = z.object({
  used_percentage: z.number().nullish(),
  resets_at: z.number().nullish(),
});
const Input = z.object({
  model: z.object({ display_name: z.string() }),
  context_window: z.object({ used_percentage: z.number().nullish() }),
  rate_limits: z
    .object({ five_hour: Window.optional(), seven_day: Window.optional() })
    .optional(),
});

const ansi = {
  red: "\x1b[31m",
  yellow: "\x1b[33m",
  green: "\x1b[32m",
  reset: "\x1b[0m",
};

function pctColor(pct: number): string {
  if (pct >= 80) return ansi.red;
  if (pct >= 50) return ansi.yellow;
  return "";
}

// With a reset time, shows how far ahead of an even burn the window is; the
// colour then tracks that pace instead of the percentage.
function limitSegment(
  label: string,
  pct: number,
  resetTs: number | null | undefined,
  windowMs: number,
  formatReset: (d: Date) => string,
): string {
  if (resetTs == null) return `${pctColor(pct)}${label}:${pct}%${ansi.reset}`;
  const reset = new Date(resetTs * 1000);
  const elapsedPct =
    ((windowMs - (reset.getTime() - Date.now())) / windowMs) * 100;
  const pace = elapsedPct > 0 ? pct / elapsedPct : 0;
  const color = pace >= 1.1 ? ansi.red : pace >= 0.9 ? ansi.yellow : "";
  return `${color}${label}:${pct}% ×${pace.toFixed(2)}${ansi.reset} (${formatReset(reset)})`;
}

const input = Input.parse(await Bun.stdin.json());

const model = `[${input.model.display_name}]`;

const branchName = (
  await $`git branch --show-current`.nothrow().quiet().text()
).trim();
const branch = branchName ? `${ansi.green}${branchName}${ansi.reset}` : null;

const ctxPct = input.context_window.used_percentage;
const ctx =
  ctxPct != null
    ? `${pctColor(Math.round(ctxPct))}ctx:${Math.round(ctxPct)}%${ansi.reset}`
    : null;

const hhmm = (d: Date) =>
  d.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" });
const weekday = (d: Date) =>
  d.toLocaleDateString("en-GB", { weekday: "short" });

const fiveHour = input.rate_limits?.five_hour;
const fiveHourSegment =
  fiveHour?.used_percentage != null
    ? limitSegment(
        "5h",
        Math.round(fiveHour.used_percentage),
        fiveHour.resets_at,
        5 * 3600_000,
        hhmm,
      )
    : null;

const sevenDay = input.rate_limits?.seven_day;
const sevenDaySegment =
  sevenDay?.used_percentage != null
    ? limitSegment(
        "7d",
        Math.round(sevenDay.used_percentage),
        sevenDay.resets_at,
        7 * 86400_000,
        (d) => `${weekday(d)} ${hhmm(d)}`,
      )
    : null;

// Sections are separated by |; the two limits within their section by -.
const limits = [fiveHourSegment, sevenDaySegment].filter(Boolean).join(" - ");
const sections = [[model, branch].filter(Boolean).join(" "), ctx, limits];
console.log(sections.filter(Boolean).join(" | "));
