---
name: buying-guide
description:
  Research a purchase and present it as a Wirecutter-style buying guide
  artifact, with live-verified prices, owned-device measurements and a
  fact-check pass. Use whenever Étienne asks what to buy, which model to pick,
  or for a buying guide or product comparison (laptops, desks, gear).
---

# Buying guide

## Requirements to apply by default

- Keyboards: US ANSI layout. ISO "US English" or "English (EU)" layouts do not
  count; say so when a vendor only offers those.
- Étienne is a VAT-registered freelancer in Germany: show every price gross and
  net (gross ÷ 1.19).
- Prices are for buying in Germany unless he says he is travelling; then also
  compare those countries (see Buying abroad).

Ask only for requirements his notes or the conversation don't already give
(budget, must-haves, deal-breakers).

## Research

Run the `deep-research` skill with parallel tracks: product and compatibility
facts, what respected people in the field actually use (with sources), how the
use case sizes the specs, and local prices.

Measure the devices he already owns instead of quoting spec sheets: SSH into
them (user `soft`; hop through `tower` if a direct connection fails) and record
battery health, cycles, specs and a benchmark relevant to the use case. Label
these "measured on device" with the date.

## Verify before publishing

- Read every price live in the vendor's own configurator, in Chrome, for the
  exact configuration recommended (layout, RAM, storage, no OS). Configurators
  render in JavaScript, so research agents can't read them; do it yourself. Date
  every price. Note pre-order and shipping dates.
- When several agents use Chrome at once, each must create and close its own
  tab; they otherwise navigate each other's tabs away.
- Price "build your own" variants: parts the buyer can source cheaper themselves
  (RAM, SSD, Wi-Fi card), from idealo or geizhals.
- Run a separate fact-check agent over every claim in the draft, against its
  cited source. Mark spec-sheet values that weren't verified with †.
- Don't state forecasts (prices falling, etc.) without a cited source.

## Buying abroad

When he is travelling, compare net prices per country:

- EU: an intra-EU B2B purchase with his USt-IdNr can be invoiced without foreign
  VAT (reverse charge); check whether each shop does this.
- Outside the EU: local tax is paid, then German import VAT at customs above the
  €430 traveller allowance, which he can reclaim.
- Note warranty region and keyboard layout availability per country.

## The artifact

Load `artifact-design` and publish an HTML page, laid out like a Wirecutter
article:

1. Headline, dek, byline with the date prices were checked.
2. Pick cards: **Top pick**, **Runner-up**, **Budget pick**, **Upgrade pick**,
   each with gross and net price.
3. Why you should trust this guide: the research done, including the
   owned-device measurements.
4. Who this is for.
5. How we picked: the criteria, which later sections refer back to.
6. One section per pick: an itemised config table (part, price, total), then
   prose and "What we like" / "Flaws but not dealbreakers".
7. **Best for…** callouts for niche winners.
8. Build your own: which parts to buy separately and which not.
9. Buying abroad, when relevant.
10. Comparison table: the picks, the current flagship reference (e.g. the latest
    MacBook) and the devices he owns, on every metric he cares about.
11. The competition: each dismissed product leads with the "How we picked"
    criterion it failed.
12. Sources.

## Revisions

Republish to the same artifact. Underline every changed passage with a solid
underline, one color per revision round, and keep a legend at the top naming
each round.
