# Data schema and caveats

## Main CSV (session-level aggregates)

Typical grain: `dt × user_type × platform × language` (and country when present).

| Column | Meaning |
|--------|---------|
| dt | YYYY-MM-DD |
| user_type | guest / new / returning |
| language, platform | as provided |
| search_sessions | SRP |
| oops | Oops page before SL |
| seatlayout_sessions / seatlayout_failures | SL views / failures |
| custinfo_sessions | Customer info |
| create_order_sessions / tentative_error_sessions / total_tentative_errors | Tentative |
| orderinfo_sessions / total_payment_attempts | Payment page |
| total_txns / total_seats / GMV | Bookings |
| discount_txns / reddeal_txns | Mix |
| payment_success_rate | Optional |

Use main CSV for **deduplicated shopper counts** and L0 dims.

## Slices CSV (route-level)

Grain: session × route × L1 dims (`doi`, Source, Destination, Region_Final, dbd, …).

| Note | Rule |
|------|------|
| Counts > main CSV | Same 30-min session searching two routes → two slice rows |
| Compare to main | Never compare absolute sessions; use **CR% and shares** |
| L1 dims | region, DBD, route, route_type (where cities mapped) |

## Data explosion

Main = session-level. Slices = intentionally higher for attribution. Document coverage when deriving dims (e.g. route_type only where Source/Destination exist).

## Aggregation of seats / ASP

Before `groupby(dt).first()` on `total_seats`, inspect the file:

- **Per-row partials** at dt × dims → `.sum()`  
- **Repeated daily total** on every row → `.first()` or divide  

Wrong choice silently wrecks seats and ASP.

## Common APIs (CR Analytics app)

`/api/meta`, `/api/kpis`, `/api/cr-trend`, `/api/funnel`, `/api/dimension/{dim}`, `/api/insights`, `/api/seats`, `/api/period-comparison`, `/api/filter-options`, `/api/transaction-mix`, `/api/chat`

Common filters: `start_date`, `end_date`, `filter_user_type`, `filter_platform`, `filter_language`, `filter_region`, `filter_dbd`.

Region/DBD/(route_type) usually served from slices engine; other dims from main engine.

## Stack notes

- FastAPI + single-file HTML frontend; CSV paths via env (`CSV_DATA_PATH`, `SLICES_DATA_PATH`)
- Future: Iceberg / warehouse via connectors in the Downloads pack
- Funnel SQL templates: `funnel_dimensions/*.sql` in the Downloads `.cursor` folder
