

---

## #1 — Generic "go check X" recommendations in alert actions

**Date:** 2026-06-14

 **Where it appeared:** `/api/alerts` action text, `/api/summary` weekly insights action text
**What was wrong:**
Hardcoded strings like:

- `"Compare by user type and platform to isolate the affected segment."`
- `"segment by user type, and cross-reference with error rate spikes"`
- `"Check if errors were concentrated in a specific user type or time window"`

These are lazy placeholders. The system already has the dimension data (user_type, channel, DBD, region splits). Recommending "go check X" when you could have checked X and reported the result is unhelpful and misleading.

**The rule:**

> If the system has access to a dimension cut, it must CHECK it and report what it found — either name the culprit segment or explicitly say "nothing visible here". Never say "compare by X" without first running that comparison.

**Fix applied:**

- Alert action now calls `_smart_action(delta)` which:
  1. Pulls user_type and channel CR splits from the slices engine for yesterday vs day_before
  2. If one segment's delta ≥ 1.5× the overall delta → names that segment
  3. If splits are uniform → says "nothing isolated in product dimensions — validate tech logs"
- Weekly summary actions updated to point to specific next steps (Funnel tab, WoW narrative, deploy history) instead of generic "segment by user type" guidance

**Pattern to avoid in future:**
Any action/recommendation string that says:

- "Compare by [dimension]..."
- "Check if [metric] was concentrated in [segment]..."
- "Segment by [X] to isolate..."

...unless the system genuinely cannot access that data. If the data exists, use it.

---

## #2 — route_type classification only covers countries where slices data has Source/Destination

**Date:** 2026-03-25
**Where it appeared:** `route_type_mapping.py`, `slices_engine.py`
**What was wrong:** 

User asked if it covers all countries.  Route_type can only be derived where Source/Destination city columns exist.

**The rule:**

> When adding a derived dimension, immediately document which countries/data sources it covers and which it doesn't. Never silently fall back to a default without noting the coverage gap.

**Fix applied:**

- Mapping currently covers all Malaysian cities
- Fallback is "tier-3" for unmapped cities (acceptable default for unknown cities)
- CITY_PAIR_DISTANCE is a placeholder ready for the user's distance file
- Extension path: add `CITY_CATEGORY` entries per country once slices files arrive

**Pattern to avoid:**
Implementing a feature for one country and not flagging that other countries aren't covered yet.

---

## #3 — New dimension added to engine but not wired to filter bar and dimension breakdown tab

**Date:** 2026-03-25
**Where it appeared:** `route_type` dimension — added to `slices_engine.py` and `main.py` but the filter dropdown and dimension tab were missing from the frontend, and the `apply()` derivation was too slow to load.
**What was wrong:**
Two separate failures:

1. Used `df.apply(lambda r: get_route_type(...), axis=1)` on 2.7M rows — this is O(n) Python-level iteration, takes minutes. Server appeared stuck, route_type never appeared.
2. Added `route_type` to engine and backend routes but did not verify the full chain: filter dropdown → `state.filters` → `buildFilterParams()` → API param → `_parse_filters()` → dimension tab → `loadDim()`. One missing link = feature is invisible to the user.
3. Only added Malaysian city classifications despite the platform operating across 9 countries.

**The rule:**

> When adding any new dimension: (a) use vectorized pandas operations, never `apply()` on large DataFrames; (b) trace the FULL chain from engine → API → filter dropdown → state → buildFilterParams → dimension tab before marking done; (c) add classifications for ALL active countries, not just the one in the current file.

**Fix applied:**

- Replaced `apply()` with fully vectorized `.map(CITY_CATEGORY)` + boolean masks — processes 2.7M rows in milliseconds
- Added `sel-route_type` dropdown, `state.filters.route_type`, `buildFilterParams`, L1 visibility list, `clearAllFilters`
- Added city classifications for IND, IDN, VNM, KHM, PER, COL, SGP, RDC, Thailand cross-border

**Pattern to avoid:**

- `df.apply(lambda r: ..., axis=1)` on DataFrames with >100k rows
- Implementing a backend feature without immediately testing the full frontend chain end-to-end

---

## #4 — route_type not visible in dashboard because server not restarted; misdiagnosed and incorrectly removed

**Date:** 2026-03-25
**Where it appeared:** `route_type` filter dropdown and dimension breakdown tab
**What was wrong:**
The route_type dropdown was hidden (start `display:none`, shown only when filter-options API returns it). The server had not been restarted with the new vectorized derivation code, so filter-options never returned route_type → dropdown never became visible. This was misread as "wrong placement" and the filter was removed entirely.

**The rule:**

> When a filter/dimension is not showing, check whether the SERVER has been restarted with the new code before changing any frontend or backend logic. A hidden element that never gets shown is a server/data pipeline problem, not a layout problem.

**Fix applied:**

- Restored route_type as BOTH a filter dropdown in the filter bar AND a dimension breakdown tab
- Root cause: server needs restart for slices engine to derive `route_type` column using vectorized `.map(CITY_CATEGORY)`
- Once server restarts, filter-options returns route_type → `sel-route_type` becomes visible → filter and breakdown both work

**Pattern to avoid:**
Do not remove working frontend wiring because a feature is not visible. Always check server state first.

---

## #5 — New slices dimension not added to the hardcoded list in /api/filter-options

**Date:** 2026-03-25
**Where it appeared:** `main.py` `/api/filter-options` endpoint, line `for dim in ("region", "dbd")`
**What was wrong:**
Every time a new dimension is added to the slices engine, `filter_options()` has a hardcoded tuple `("region", "dbd")` that controls which slices dims get exposed to the frontend. New dims added to `DIM_COL_MAP` and `SLICES_DIMS` are invisible until this tuple is also updated.

**The rule:**

> Do not hardcode dimension names in `filter_options()`. Either iterate over all `slices_opts` keys, or maintain a single source-of-truth list. Every time a new slices dimension is added, the filter-options endpoint must also be updated.

**Fix applied:**

- Changed `for dim in ("region", "dbd")` → `for dim in ("region", "dbd", "route_type")`
- Long-term fix: replace with `for dim in slices_opts` to auto-expose all available slices dims

**Pattern to avoid:**
Any hardcoded dimension list in an endpoint that is supposed to reflect dynamic available dims.

---

## #6 — `total_seats` deduplication logic broke seats count and ASP when CSV granularity changed

**Date:** 2026-03-25
**Where it appeared:** `csv_data_engine.py` — `_agg()` inside `get_kpis()`, `get_dimension_breakdown()`, and `get_seats_impact()`
**What was wrong:**
The code had a comment saying "total_seats is a daily-level total repeated across all dimension rows — deduplicate per date before summing". Based on this assumption it used `df.groupby("dt")["total_seats"].first().fillna(0).sum()` — picking only the **first** row per date.

In the updated CSV (feb_data_check2.csv), `total_seats` is stored **per row** at the granularity of dt × user_type × platform × language × country. There is no repetition — each row contributes its own partial seats count. Using `.first()` silently discards 98%+ of the data.

**Effect on dashboard:**

- India Mar 17 actual seats = 297,547 → dashboard showed ~168K (across the full period, `.first()` per day picked only one user_type combo, ~5,900–8,000 seats/day)
- ASP correct ≈ ₹982/seat → dashboard showed ≈ ₹1,800/seat (GMV was correctly summed; seats denominator was ~58% of truth → ASP inflated by ~1.8×)

**The rule:**

> Before writing any deduplication logic for an aggregation column, verify whether that column is (a) a repeated daily total or (b) a per-row partial value. If it's per-row, always `.sum()`. If it's a daily total repeated N times, `.first()` or divide-by-N. The comment alone is not proof — check the raw CSV.

**Fix applied:**

- Removed all three `groupby("dt")["total_seats"].first()` calls
- Replaced with `df["total_seats"].fillna(0).sum()` in `get_kpis()`, `get_dimension_breakdown()`, and `get_seats_impact()`

**Pattern to avoid:**

- Trusting a comment that says "this value is repeated" without verifying the actual CSV structure
- Any `groupby(date_col)[metric].first()` pattern — it silently drops all but the first row of each group

---

## #7 — `--reload` + debug prints = infinite reload loop; always validate numbers via direct Python before dashboard

**Date:** 2026-03-25
**Where it appeared:** Server restart workflow after code fix in `csv_data_engine.py`
**What was wrong:**
Two compounding mistakes:

1. Added a temporary `print(f"DEBUG ...")` to a file being watched by uvicorn's `--reload`. Every save triggers a reload, and a reload triggers another file-change detection → infinite loop. Server never stabilises.
2. Instead of validating the fix directly via Python first, jumped straight to checking the dashboard — wasted multiple restart cycles before confirming whether the fix was even correct.

**The rule:**

> (a) Never add debug prints to files watched by `--reload` — use a separate test script instead. (b) Before asking the user to refresh the dashboard, always run a direct Python test (`py -3 -c "from csv_data_engine import ... ; print(result)"`) to confirm the fix returns the right number. Only then restart the server.

**Fix applied:**

- Removed debug print before restarting
- Direct Python test confirmed: Mar 18 India seats = 290,624 ✓, ASP = ₹1,029 ✓

**Pattern to avoid:**

- Adding any `print()` debug statements to source files when `--reload` is active
- Asking the user to refresh the dashboard to validate a fix that hasn't been confirmed in isolation first

---

## #8 — Template for future entries

```
## #N — Short description
**Date:** YYYY-MM-DD
**Where it appeared:** file/endpoint/component
**What was wrong:** exact text or behaviour
**The rule:** one-sentence principle to remember
**Fix applied:** what was changed
**Pattern to avoid:** concrete anti-pattern
```

