# Metrics and booking funnel

## Funnel (order)

1. **SRP Sessions** — search results page
2. **Seat Layout Views** — opens a bus seat map
3. **Customer Info** — passenger details (RAP / Free Cancellation / Insurance add-ons possible)
4. **Create Order (Tentative)** — seat hold; tentative failure = concurrent hold conflict
5. **Order Info / Payment Page**
6. **Transaction** — payment processed
7. **Booking Confirmed**

## Formulas

| Metric | Formula |
|--------|---------|
| CR | Transactions / SRP Sessions × 100 |
| ASP | Total GMV / Total Seats (₹ per seat, v1) |
| Oops Rate | Oops Sessions / SRP Sessions × 100 |
| SL Failure Rate | Seat Layout Failures / Seat Layout Sessions × 100 |
| Tentative Error Rate | Total Tentative Errors / Create Order Sessions × 100 |
| Payment Drop Rate | 1 − (Transactions / Order Info Sessions) × 100 |
| RedDeal % | reddeal_txns / total_txns |
| Discount % | discount_txns / total_txns |
| Seats Lost (est.) | error_sessions × (total_seats / total_txns) |

## Analysis dimensions

| Level | Dimension | Typical values |
|-------|-----------|----------------|
| L0 | user_type | guest / new / returning |
| L0 | platform / channel | android, ios, mobile_web, web_direct, others |
| L0 | language | market-specific (IN: en/hi/ta/…; MY slices: en/ms/id/vi) |
| L1 | region | from slices (geo-specific) |
| L1 | DBD | sameday lmb, sameday non lmb, next day, 2 days, more than 2 days |
| L1 | route | Source / Destination city |
| L1 | route_type | derived from city mapping where Source/Destination exist |
| L1 | route_length / operator | planned or partial |

## KPI card set (dashboard)

Conv. Rate, SRP Sessions, Bookings, Error Rate (tentative), Payment Drop, Seats Booked, Seats Lost (est.) — each with DoD delta (green = improvement).
