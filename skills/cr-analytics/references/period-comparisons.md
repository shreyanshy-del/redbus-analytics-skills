# Period comparisons

Shared metrics: CR%, SRP Sessions, Bookings, Error Rate, Payment Drop, Seats Booked, Seats Lost.

Delta for volumes: `(A − B) / |B| × 100`. For rate metrics prefer **pp** change where clearer.

Default alerts: CR −0.5pp WARNING, −1.0pp CRITICAL; error rate +3pp CRITICAL.

---

## DoD (`/dod`)

**Purpose:** Morning ops — did yesterday move vs the prior day?

| | |
|-|-|
| Period A | Yesterday (anchor) |
| Period B | Anchor − 1 day |

**RCA when breached**

1. Funnel step with largest absolute drop  
2. Platform / user_type / language cuts — report findings  
3. Tentative error + payment drop  
4. Team context (launches, outages, campaigns)

---

## WoW same-day (`/wow-day`)

**Purpose:** Remove day-of-week bias (Fri/Sun peak; Mon/Tue low). Use when DoD looks bad.

| | |
|-|-|
| Period A | Yesterday |
| Period B | Same weekday, −7 days |

**Interpretation**

| WoW same-day drop | Action |
|-------------------|--------|
| < 5% | Normal weekly variance |
| 5–10% | Investigate |
| > 10% | Escalate |

If DoD drop vanishes on WoW → weekday pattern. If WoW also drops → genuine decline → full RCA.

Also check acquisition mix if web data exists ([web-analytics.md](web-analytics.md)).

---

## WoW 7-day (`/wow-week`)

**Purpose:** Weekly health / BBR — smooths single-day noise.

| | |
|-|-|
| Period A | Anchor−6 … Anchor (rates = average; volumes = totals) |
| Period B | Anchor−13 … Anchor−7 |

**RCA**

1. Which days drove the gap?  
2. 1–2 spike days → incident RCA on those days  
3. Consistent across week → structural (mix, operators, route type)

---

## MoM (`/mom`)

**Purpose:** Mid-month / leadership — tracking vs last month same calendar position.

| | |
|-|-|
| Period A | 1st of month → today |
| Period B | 1st of last month → same # of days |

Always same day-count (Feb shorter). Note festivals/holidays in either window.

**RCA:** concentration by week; seasonality; platform mix; user_type / acquisition; major operator outages.
