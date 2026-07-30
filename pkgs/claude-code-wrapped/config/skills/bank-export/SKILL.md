---
name: bank-export
description:
  Refresh Étienne's bank transaction data in ~/sync/doc/finances/bank-exports/,
  and decide how to automate bank-data access. Use whenever he asks to update,
  refresh or export bank / N26 / Trade Republic transactions, wants spending data
  brought up to date before an analysis, or proposes automating access to bank
  data (n26 CLI, scraping, open banking / PSD2).
---

# Refresh bank exports

Exports live in `~/sync/doc/finances/bank-exports/`.
`finances/spending-analysis.md` records how the data is analysed and its caveats.

## N26

Every N26 export is the **full account history**, so a fresh export supersedes
the previous file entirely — there is never any merging to do.

The login cannot be automated: N26 needs a password plus an approval tap in the
phone app. `export.js` (next to this file) opens a visible Chrome, waits for
Étienne to get through the login, then drives the rest. Ask him to log in when
the window appears — never ask for the password.

One-time setup. `playwright-core` is installed outside the repo so that a
`node_modules` tree never lands in `setup`:

```bash
mkdir -p ~/.cache/bank-export && cd ~/.cache/bank-export
npm install playwright-core
```

Then run it, pointing `--supersedes` at the newest existing N26 export:

```bash
NODE_PATH=$HOME/.cache/bank-export/node_modules node export.js \
  --supersedes ~/sync/doc/finances/bank-exports/2026-07-30_n26_transactions.csv \
  --out ~/sync/doc/finances/bank-exports/$(date +%F)_n26_transactions.csv
```

The script already guarantees the things that are easy to skip by hand, so don't
redo them: it reads the date range back out of the form before submitting, it
refuses to file an N26 error body that arrived under a `.csv` name, and with
`--supersedes` it will not write the output unless every row of the existing
export is present in the new one. It deletes the browser profile afterwards,
which matters because that profile holds a live N26 session.

Constraints it encodes, worth knowing if it ever breaks:

- The start date must be on or after the account open date, **2020-07-17**. An
  earlier date returns `Bad Request: from must be equal or after account open
date` as a JSON body saved under the `.csv` filename, so it looks like a
  successful download.
- The date inputs carry no `type` attribute, so `input[type=text]` does not match
  them.
- Downloads reuse the same filename, so a second export overwrites the first.
- **Only the Main Account is exported.** Ahorros and other Spaces are separate.

The selectors are a snapshot of the N26 web app. If a step fails, re-probe the
page (screenshot it, dump the interactive elements) rather than assuming N26 is
down.

Because each file is a strict superset of the one before, they accumulate fast at
any regular cadence. Prune old exports rather than keeping every dated copy.

## Trade Republic

There is no scripted export. The existing
`bank-exports/*_trade-republic_transactions.csv` files were produced by hand.

**Trade Republic is where roughly 99% of Étienne's day-to-day card spending
happens.** N26 carries rent, direct debits and income. So for any question about
spending, Trade Republic is the account that matters, not N26.

Trade Republic publishes a real
[PSD2 TPP guide](https://assets.traderepublic.com/assets/files/TPP_API_Guide_v2.pdf)
(v2.1, July 2026) with an AIS interface, and since its 2023 full banking licence
it issues individual IBANs with direct debits and standing orders. Whether that
is reachable is **unresolved**:

- Direct access needs an **eIDAS QSeal certificate** and a licensed AISP or PISP,
  which an individual cannot obtain. It has to go through an aggregator.
- Whether GoCardless lists Trade Republic as an institution is unknown. Third
  party coverage pages are unreliable here — the one claiming only Powens covers
  it also claimed Trade Republic had no PSD2 API at all, which its own
  documentation disproves. Settle it by calling the institutions endpoint
  (`country=de`), which needs only a free GoCardless account.
- AIS exposes the cash account only, with no securities positions or trades. For
  **spending** that is sufficient — card payments debit the cash account — so the
  limitation does not bite. It only matters for investment tracking.

Resolve the coverage question before building anything. If Trade Republic is
reachable, unattended spending data becomes possible; if it is not, no amount of
N26 automation substitutes for it.

Keep the manual export regardless for investment detail: it carries
`asset_class`, `symbol` (ISIN), `shares`, `price`, `fee` and `tax`, which no
open-banking feed returns.

## Automating this — read before proposing anything

- **Do not use the `python-n26` CLI.** MFA has been broken since 2023
  ([issue #134](https://github.com/femueller/python-n26/issues/134)) and the
  project has been unmaintained since October 2023. Worse, repeated failed logins
  against the unofficial endpoint risk locking the real bank account. The
  header-spoofing workaround in that thread worked for some people and not
  others, and pins itself to a 2022 Android build.
- **Open banking (PSD2) is the right destination for N26.**
  [GoCardless Bank Account Data](https://developer.gocardless.com/bank-account-data/overview)
  (formerly Nordigen) is free for personal use, supports N26 Germany, and
  authorizes through N26's own consent screen so no password is shared.

  Access is not indefinite. EU law requires strong customer authentication for
  account access periodically —
  [Commission Delegated Regulation 2022/2360](https://www.projectivegroup.com/psd2-alert-authentication-period-for-account-information-services-extended-to-180-days/)
  raised that interval from 90 to **180 days** as of July 2023. GoCardless's own
  documentation still states 90 days of continuous access, so assume 90 and
  confirm at setup. Either way it is a legal floor, not a tool limitation: no
  integration can make bank access permanently unattended.

- **The browser route can never be scheduled.** N26's device approval means a
  human is always required, so any request for unattended or cron-driven syncing
  has to go through PSD2, not `export.js`.
- **Never answer a money question without checking how fresh the data is.** The
  exports are snapshots and go stale silently. Read the newest file's last row
  date before reasoning from it, and say so if it predates the period in
  question.
