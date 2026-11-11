# ILP Studio — policy projection

Private working copy of the ILP projection tool. The app itself is a single file,
`index.html` — no build step, no dependencies, no network calls. Open it directly
(or use the desktop shortcut on the machine where it is maintained).

## What it models

Per plan and per policy year: premium, banded welcome bonus, special/investment/
performance bonuses, supplementary charge and its window, surrender charge, cash-out
value, and quarterly fund dividends (reinvested or taken as cash) — out to age 100,
with ad-hoc top-ups, a promotional bonus and an adjustable assumed return.

## Verification

The engine is a line-by-line port of the source spreadsheet's formulas and re-checks
itself on every load: with **sheet-exact** on it reproduces all 180 yearly
account-value figures (6 plans x 30 years) to the cent.

## Corrections applied by default

1. The three PWV tabs never applied the assumed return in the spreadsheet; the
   account now grows like every other plan.
2. APA and AWV credit the welcome bonus only in year 1 in the spreadsheet.
3. Invest Easy charges its 3% entry fee twice in year 1.

## Status

**Private, no public site.** GitHub Pages needs a public repo on a free plan, so
there is no shareable link. For client-facing use, host elsewhere (or make this
public and enable Pages).

Reference illustration only — not advice, not a forecast.
