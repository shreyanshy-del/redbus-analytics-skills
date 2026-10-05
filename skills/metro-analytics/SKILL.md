---
name: metro-analytics
description: >-
  redBus Metro ticketing analytics: city DRR/seats/unique/new users, metro-acquired
  cohort retention (same city vs any metro), and metro-to-bus cross-sell retention.
  Use when the user asks about Metro, metro tickets, metro cohort, metro retention,
  metro new users, metro DRR, metro seats/rides, metro-acquired users, metro → bus
  conversion, or city-level metro performance (Bangalore, Chennai, Delhi, Ernakulam,
  Mumbai, Pune).
---

# Metro Analytics

Domain skill for redBus **Metro ticketing** (addon) analytics on Data Platform / Iceberg.

Prefer **dataplatformCreateQuery** then execute generated/adapted SQL via **dataplatformExecuteIcebergQuery**. Default country **IND**. Use the canonical SQL in `references/` — swap only the `params` dates the user asks for.

## Quick routing

| User intent | Do this |
|-------------|---------|
| Daily DRR / txns / seats / unique / new users | [daily-drr-seats-new-users.sql](references/daily-drr-seats-new-users.sql) |
| Metro-acquired cohort → retain on metro (same city / any metro) | [cohort-metro-retention.sql](references/cohort-metro-retention.sql) |
| Metro-acquired cohort → later bus (same city / any bus) | [cohort-bus-cross-sell.sql](references/cohort-bus-cross-sell.sql) |
| Provider ↔ city mapping / filters | **Canonical filters** below |

## Canonical filters (never invent)

### Metro confirmed ticket (`transaction.addon_item`)

```
country_code = 'IND'          -- include on DRR query; cohort SQLs may omit if scoped by provider
item_type = 13
s_c_t = 'Ticket'
c_t = 'METRO_TICKETING'
event_type = 101
status = 'CONFIRMED'
tin IS NOT NULL
rb_user_id IS NOT NULL AND rb_user_id <> 0   -- for user/cohort metrics
```

### Bus / Rail / Hotel (BRH) “existing customer” exclusion

Used only to define **metro-acquired** (exclude anyone who already booked BRH in the acquisition window):

| Vertical | Table | Time column | Country |
|----------|-------|-------------|---------|
| Bus | `transaction.bus_ticket_events` | `time_of_event` | `country_code = 'IND'` |
| Rail | `transaction.rail_ticket_events` | `date_of_issue` | `country = 'IND'` |
| Hotel | `transaction.hotel_booking_events` | `date_of_issue` | `country_code = 'IND'` |

Common BRH filters: `event_class = 2`, `event_type = 101`, valid `rb_user_id`.

### Metro provider → city map

```
MaharashtraMetroRailCoLtd              → Pune
Mumbai Metro One Pvt Ltd               → Mumbai
Bangalore Metro Rail Corporation Limited → Bangalore
Mumbai Metro Rail Corporation Limited  → Mumbai
Kochi Metro Rail Limited               → Ernakulam
Maha Mumbai Metro Operation Corporation Limited → Mumbai
Chennai Metro Rail Limited             → Chennai
Delhi Metro Rail Corporation           → Delhi
```

City display order: Overall → Bangalore → Chennai → Delhi → Ernakulam → Mumbai → Pune.

## Definitions

### Metro-acquired cohort

1. **First metro ever** = `MIN(time_of_event)` of confirmed metro txns from `lifetime_start`.
2. Restrict to first metro in **`[acq_start, acq_end)`**.
3. **Acquisition city** = city of that first metro txn (`MIN_BY(city, time_of_event)` on ties).
4. Drop users who have **any BRH confirmed txn in the same acq window** (left-anti join).
5. Remaining users = **metro-acquired new users** for that city.

### Retention windows

Relative to `cohort_date` (first metro ts), exclusive of the acquisition txn itself (`time_of_event > cohort_date`):

| Flag prefix | Meaning |
|-------------|---------|
| `same_*` | Repeat activity in **acquisition city** within 30 / 90 / 180 / 365 days |
| `any_*` | Repeat activity in **any** mapped metro city (or any IND bus for cross-sell) within those windows |

### Bus “same city” match (cross-sell only)

Bus row matches acquisition city when `source_location = city OR destination_location = city` for the six metro cities.

### Daily DRR metrics (IST calendar)

- Window default: last 30 complete IST days (`start_ist` → `< today_ist`).
- Deduplicate to **one row per `tin`** before aggregating.
- **Seats / rides**: parse `quantity` (JSON array or CSV-like string); `GREATEST(..., 1)` so every txn counts ≥1 seat.
- **New users (city)**: first-ever metro txn that day **and** first city = that metro.
- **New users (Overall)**: first-ever metro txn that day (any city).

## Params to edit

Cohort SQLs:

```sql
acq_start        -- cohort acquisition window start
acq_end          -- exclusive end
lifetime_start   -- usually 2015-01-01 (true first-metro lookback)
retention_end    -- how far post-acq to scan for retention
```

DRR SQL uses rolling IST dates (`CURRENT_TIMESTAMP` → `Asia/Kolkata`); override `start_ist` / `today_ist` if user asks for a fixed range.

## Workflow

```
Metro ask:
- [ ] 1. Classify: daily ops (DRR) vs cohort retention vs metro→bus
- [ ] 2. Confirm dates (acq window / lookback) with user defaults if missing
- [ ] 3. Load matching reference SQL; substitute params only
- [ ] 4. Run via dataplatform MCP (CreateQuery optional if adapting; Execute with final SQL)
- [ ] 5. Report city table + call out outliers vs Overall
```

## Output style

- Lead with the metric the user asked for (e.g. 30d same-city metro retention %, or yesterday DRR).
- Show **city × cohort_users / txns** plus the retention or DRR columns; keep Overall when present.
- State filters briefly: IND, confirmed metro (`event_type=101`, `status=CONFIRMED`), metro-acquired definition if cohort.
- Do not invent providers, cities, or filters outside this skill.

## Additional resources

- [daily-drr-seats-new-users.sql](references/daily-drr-seats-new-users.sql)
- [cohort-metro-retention.sql](references/cohort-metro-retention.sql)
- [cohort-bus-cross-sell.sql](references/cohort-bus-cross-sell.sql)
