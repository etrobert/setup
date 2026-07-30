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

Don't reach for open banking here, even though Trade Republic does publish a
[PSD2 TPP guide](https://assets.traderepublic.com/assets/files/TPP_API_Guide_v2.pdf)
(v2.1, July 2026) describing a real AIS interface. Three things rule it out:

- Access needs an **eIDAS QSeal certificate** and a licensed AISP or PISP. That
  is an institutional requirement, not something an individual obtains.
- So it is only reachable via an aggregator that has integrated Trade Republic.
  GoCardless does not appear to list it. Powens does, but Powens is B2B with
  sales-gated pricing and only a development sandbox for free — there is no
  self-serve production tier for an individual. Don't go down this road.
- AIS exposes the **cash account only** — balances and booked transactions. No
  securities positions and no trades. That is precisely the part of Trade
  Republic worth having, so even a working connection would miss the point.

The existing export is already richer than anything open banking would return:
it carries `asset_class`, `symbol` (ISIN), `shares`, `price`, `fee` and `tax` for
trades alongside `counterparty_iban` and `mcc_code` for cash and card movements.
Keep using it.

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
  authorizes through N26's own consent screen so no password is shared. Access
  needs re-consent every 90 days. That trade only pays off above roughly monthly
  pulls; below that, the browser export is cheaper than maintaining a
  registration.
- **The browser route can never be scheduled.** N26's device approval means a
  human is always required, so any request for unattended or cron-driven syncing
  has to go through PSD2, not `export.js`.
