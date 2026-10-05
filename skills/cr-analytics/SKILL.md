---
name: cr-analytics
description: >-
  redBus / bus-booking Conversion Rate (CR) analytics and RCA. Covers funnel
  diagnostics (SRP → seat layout → cust info → tentative → payment → txn),
  DoD/WoW/MoM period comparisons, mix-shift vs operational causation, shopper
  spike investigation, ASP/RedDeal/discount mix, Oops/SL/Tentative/Payment Drop
  error drivers, web acquisition layer, and India/SEA geo context. Use when the
  user asks about CR, conversion rate, funnel drops, booking RCA, /dod, /wow-day,
  /wow-week, /mom, /web, SRP sessions, Oops rate, tentative failures, or CR Analytics.
---

# CR Analytics

Domain skill for redBus booking-funnel conversion analysis. Background material (LESSONS_LEARNED, analyser file guide) lives in the repo's `docs/` folder.

## Quick routing

| User intent | Do this |
|-------------|---------|
| `/dod` or yesterday vs day before | [period-comparisons.md](references/period-comparisons.md) → DoD |
| `/wow-day` or same weekday last week | period-comparisons → WoW same-day |
| `/wow-week` or last 7 vs prior 7 | period-comparisons → WoW 7-day |
| `/mom` or month so far vs last month | period-comparisons → MoM |
| `/web` or acquisition / landing | [web-analytics.md](references/web-analytics.md) |
| CR drop / funnel RCA | Follow **RCA workflow** below |
| Metric definition / formula | [metrics-and-funnel.md](references/metrics-and-funnel.md) |
| CSV / API / slices caveats | [data-schema.md](references/data-schema.md) |
| Hard-won rules | [lessons-learned.md](references/lessons-learned.md) |
| India market notes | [india.md](references/india.md) |

## Core formulas (always)

```
CR                    = Transactions / SRP Sessions × 100
ASP                   = Total GMV / Total Seats
Oops Rate             = Oops Sessions / SRP Sessions × 100
SL Failure Rate       = Seat Layout Failures / Seat Layout Sessions × 100
Tentative Error Rate  = Total Tentative Errors / Create Order Sessions × 100
Payment Drop Rate     = 1 - (Transactions / Order Info Sessions) × 100
```

Funnel order: **SRP → Seat Layout → Cust Info → Create Order (Tentative) → Order Info / Payment → Transaction → Confirmed**.

## RCA workflow (CR dropped?)

Copy and track:

```
RCA Progress:
- [ ] 1. Confirm CR delta and which side moved (txns down vs SRP up)
- [ ] 2. Mix check (user_type / DBD / channel / language) → Expected CR
- [ ] 3. Day-of-week / WoW same-day baseline
- [ ] 4. Error rates (Oops, SL Fail, Tentative, Payment Drop)
- [ ] 5. Funnel step with largest absolute drop
- [ ] 6. Name culprit segment OR say "nothing isolated"
- [ ] 7. Label structural vs operational
```

### Decision tree

```
CR dropped?
├── SRP Sessions INCREASING?
│   └── Check Oops Rate. Rising sessions + rising Oops = early failures absorbing traffic.
└── Transactions flat/falling?
    └── Walk funnel; attribute to Oops / SL Fail / Tentative / Payment Drop.
```

### Structural vs operational

```
Expected CR = Σ (segment_share_today × segment_CR_last_week)

Actual ≈ Expected (gap ≤ ~0.3pp) → CORRELATION / structural (mix or weekday)
Actual < Expected               → CAUSATION / operational (residual gap matters)
```

### Shopper spike (SRP up unexpectedly)

1. **Shopper mix** — region, DBD, user_type, channel, language  
2. **Txn mix quality** — ASP, RedDeal %, Discount %  
3. **Funnel & errors** — only if 1–2 don't explain it  

Full detail: [rca-framework.md](references/rca-framework.md).

## Hard rules (never violate)

1. **Never recommend "go check X"** if dimension data is available — run the cut and report the culprit or "nothing visible".
2. **Never compare raw session counts** between main CSV and slices CSV (slices explode by route/DBD). Use CR% and shares from slices.
3. **Seats / ASP**: verify whether `total_seats` is per-row partial (`.sum()`) or repeated daily total before aggregating.
4. Prefer **vectorized** pandas; never `df.apply(..., axis=1)` on large slices frames.
5. Validate metric numbers in a direct Python check before blaming the dashboard UI.

## Period comparison defaults

| Mode | Period A | Period B |
|------|----------|----------|
| DoD | Yesterday | Day before |
| WoW same-day | Yesterday | Same weekday −7d |
| WoW 7-day | Last 7 days | Prior 7 days |
| MoM | Month 1 → today | Same # of days last month |

**Alert heuristics** (tune if user specifies): CR drop > 0.5pp WARNING, > 1.0pp CRITICAL; error rate +3pp CRITICAL; WoW same-day drop > 10% escalate.

Standard KPI set for every comparison: CR%, SRP Sessions, Bookings, Error Rate, Payment Drop, Seats Booked, Seats Lost (est. = error_sessions × avg_seats_per_txn).

## Output style

- Lead with verdict: **structural** vs **operational**, and the primary driver.
- Show current / prior / delta for the KPI set.
- Name the worst funnel step and the segment (if any) with ≥1.5× overall delta.
- End with one concrete next action (not a generic "segment by…").

## Additional resources

- [metrics-and-funnel.md](references/metrics-and-funnel.md)
- [rca-framework.md](references/rca-framework.md)
- [period-comparisons.md](references/period-comparisons.md)
- [data-schema.md](references/data-schema.md)
- [web-analytics.md](references/web-analytics.md)
- [lessons-learned.md](references/lessons-learned.md)
- [india.md](references/india.md)
