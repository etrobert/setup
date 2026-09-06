#!/usr/bin/env node
// Pull a full N26 transaction CSV by driving the Playwright-cached Chrome over CDP.
//
// N26 requires a password plus an approval tap in the phone app, so the login
// cannot be automated. This script opens a visible window, waits for the human
// to get through it, then drives the rest and validates the result.
//
// usage:
//   node export.js [--start YYYY-MM-DD] [--end YYYY-MM-DD]
//                  [--account "Main Account"] [--out <path>]
//                  [--supersedes <existing.csv>] [--port 9222]

const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawn, execSync } = require("child_process");

let chromium;
try {
  ({ chromium } = require("playwright-core"));
} catch {
  console.error(
    "playwright-core not found. Install it once with:\n" +
      "  mkdir -p ~/.cache/bank-export && cd ~/.cache/bank-export && npm install playwright-core\n" +
      "then run this script with:\n" +
      "  NODE_PATH=$HOME/.cache/bank-export/node_modules node export.js",
  );
  process.exit(1);
}

// --- args -------------------------------------------------------------------

const arg = (name, fallback) => {
  const i = process.argv.indexOf("--" + name);
  return i > -1 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
};

const today = () => new Date().toISOString().slice(0, 10);

// N26 rejects any start date before the account was opened, returning a JSON
// error body saved under the .csv filename rather than an HTTP error.
const ACCOUNT_OPENED = "2020-07-17";

const START = arg("start", ACCOUNT_OPENED);
const END = arg("end", today());
const ACCOUNT = arg("account", "Main Account");
const PORT = arg("port", "9222");
const SUPERSEDES = arg("supersedes", null);
const OUT = arg("out", null);

// --- chrome -----------------------------------------------------------------

function findCachedChrome() {
  const root = path.join(os.homedir(), "Library/Caches/ms-playwright");
  if (!fs.existsSync(root))
    throw new Error("no ms-playwright cache at " + root);
  const revs = fs
    .readdirSync(root)
    .filter((d) => /^chromium-\d+$/.test(d))
    .sort((a, b) => Number(b.split("-")[1]) - Number(a.split("-")[1]));
  for (const rev of revs) {
    for (const sub of ["chrome-mac-arm64", "chrome-mac", "chrome-linux"]) {
      for (const bin of [
        "Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing",
        "chrome",
      ]) {
        const p = path.join(root, rev, sub, bin);
        if (fs.existsSync(p)) return p;
      }
    }
  }
  throw new Error(
    "no cached chromium found under " +
      root +
      " — revisions seen: " +
      revs.join(", "),
  );
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function cdpUp() {
  try {
    const res = await fetch(`http://localhost:${PORT}/json/version`);
    return res.ok;
  } catch {
    return false;
  }
}

// --- main -------------------------------------------------------------------

(async () => {
  const profile = fs.mkdtempSync(path.join(os.tmpdir(), "n26-profile-"));
  const dl = fs.mkdtempSync(path.join(os.tmpdir(), "n26-dl-"));
  const exe = findCachedChrome();
  console.log("chrome:  " + exe);

  const child = spawn(
    exe,
    [
      `--remote-debugging-port=${PORT}`,
      `--user-data-dir=${profile}`,
      "--no-first-run",
      "--no-default-browser-check",
      "--window-size=1500,1000",
      "https://app.n26.com",
    ],
    { detached: true, stdio: "ignore" },
  );
  child.unref();

  const cleanup = () => {
    try {
      process.kill(-child.pid);
    } catch {
      try {
        execSync(`pkill -f "user-data-dir=${profile}"`);
      } catch {}
    }
    // The profile holds a live N26 session — never leave it on disk.
    fs.rmSync(profile, { recursive: true, force: true });
  };

  try {
    for (let i = 0; i < 30 && !(await cdpUp()); i++) await sleep(1000);
    if (!(await cdpUp())) throw new Error("CDP never came up on port " + PORT);

    const browser = await chromium.connectOverCDP(`http://localhost:${PORT}`);
    const ctx = browser.contexts()[0];
    const pick = () => {
      const ps = ctx.pages().filter((p) => p.url().startsWith("http"));
      return ps[ps.length - 1];
    };

    console.log("\n>>> Log in in the Chrome window that just opened,");
    console.log(">>> then approve the prompt in the N26 phone app.\n");

    let page = pick();
    for (let i = 0; i < 600; i++) {
      page = pick();
      if (page && !page.url().includes("/login")) break;
      await sleep(1000);
    }
    if (!page || page.url().includes("/login")) {
      throw new Error("still on the login page after 10 minutes");
    }
    console.log("logged in: " + page.url());

    const bcdp = await browser.newBrowserCDPSession();
    await bcdp.send("Browser.setDownloadBehavior", {
      behavior: "allow",
      downloadPath: dl,
      eventsEnabled: true,
    });

    await page.locator(`button:has-text("${ACCOUNT}")`).first().click();
    await page.waitForTimeout(2000);
    await page.locator("[data-testid=Downloads-quick-action]").click();
    await page.waitForTimeout(2500);

    // Date fields are React-controlled; type then blur so state commits.
    for (const [sel, val] of [
      ["#start-date-picker", START],
      ["#end-date-picker", END],
    ]) {
      const el = page.locator(sel);
      await el.click();
      await el.fill("");
      await el.type(val, { delay: 40 });
      await el.press("Escape");
      await page.waitForTimeout(400);
    }
    await page.locator("body").click({ position: { x: 5, y: 5 } });
    await page.waitForTimeout(600);

    // Never submit on an unverified range — a silently rejected date would
    // produce a correct-looking CSV covering the wrong period.
    const state = {
      start: await page.locator("#start-date-picker").inputValue(),
      end: await page.locator("#end-date-picker").inputValue(),
      csv: await page.locator("input[type=radio][value=csv]").isChecked(),
    };
    console.log("form:    " + JSON.stringify(state));
    if (state.start !== START || state.end !== END || !state.csv) {
      throw new Error(
        "form did not accept the requested range; nothing downloaded",
      );
    }

    await page.locator("[data-testid=download-csv-submit-button]").click();

    let file = null;
    for (let i = 0; i < 90; i++) {
      await sleep(1000);
      const done = fs
        .readdirSync(dl)
        .filter((f) => f.toLowerCase().endsWith(".csv"))
        .map((f) => path.join(dl, f))
        .filter((f) => fs.statSync(f).size > 0);
      if (done.length) {
        file = done[0];
        break;
      }
    }
    if (!file) throw new Error("no CSV appeared in " + dl);

    const head = fs.readFileSync(file, "utf8").slice(0, 400);
    if (head.trimStart().startsWith("{")) {
      // N26 returns its error body under the .csv name, so this looks like success.
      throw new Error("N26 returned an error instead of a CSV: " + head.trim());
    }
    if (!/^"Booking Date"/.test(head)) {
      throw new Error("unexpected CSV header: " + head.split("\n")[0]);
    }

    const rows = fs.readFileSync(file, "utf8").trimEnd().split("\n").length - 1;
    console.log(`downloaded: ${rows} rows, ${fs.statSync(file).size} bytes`);

    if (SUPERSEDES) {
      // A full export must contain every row of the file it replaces.
      const body = (p) =>
        new Set(fs.readFileSync(p, "utf8").trimEnd().split("\n").slice(1));
      const oldRows = body(SUPERSEDES);
      const newRows = body(file);
      const missing = [...oldRows].filter((r) => !newRows.has(r));
      console.log(
        `supersedes ${path.basename(SUPERSEDES)}: ${oldRows.size} rows, ` +
          `${missing.length} missing, +${newRows.size - (oldRows.size - missing.length)} new`,
      );
      if (missing.length) {
        console.error("REFUSING: not a strict superset. Sample missing row:");
        console.error("  " + missing[0]);
        throw new Error(
          `${missing.length} rows from the existing export are absent`,
        );
      }
    }

    const dest = OUT || path.join(process.cwd(), `n26_transactions_${END}.csv`);
    fs.copyFileSync(file, dest);
    console.log("SAVED: " + dest);

    await browser.close();
  } finally {
    cleanup();
    fs.rmSync(dl, { recursive: true, force: true });
  }
})().catch((e) => {
  console.error("FAILED: " + e.message);
  process.exit(1);
});
