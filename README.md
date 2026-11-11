# ILP Studio — Policy Projection

A single-file, offline-capable projection tool for six investment-linked policy
plans (APA 3.0 10-Pay · AWV 1.0 8-Pay · PWV 3.0 5/2/1-Pay SRS · Invest Easy).

Open `index.html` — no build step, no dependencies, no network calls.

## What it models

Per plan and per policy year: premium, welcome bonus, special/investment/performance
bonuses, supplementary charge and its window, dividends (received or reinvested),
surrender charge, and cash-out value — out to age 100, with ad-hoc top-ups, an
extra promotional welcome bonus and an adjustable assumed return.

The projection engine is a line-by-line port of the source spreadsheet's formulas.
On every load the page re-runs all six plans against the source figures and shows
a parity badge (180 of 180 yearly values match to the cent).

## Notes

Reference illustration only — not advice, and not a forecast.
