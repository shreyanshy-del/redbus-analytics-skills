# Web analytics layer (`/web`)

App funnel starts at SRP. Web analytics answers **before** SRP: channel, landing page, shopper conversion.

```
Landing (channel + page) → SRP (shopper) → SL → … → Txn
```

## Acquisition channels

Organic Search, Paid Search (SEM), Direct, Social, Paid Social, Display, Referral, Email, Affiliate, App Install / Deep Link.

High-intent (organic/direct/SEM) usually higher CR. Display/social can inflate volume and depress CR via mix.

## Landing page types

Homepage, Route SRP, Operator, Promo/Offer, Blog/Content, App download, City/destination, Booking status.

Route SRP → high shopper rate. Blog → low. Promo → search OK, convert only on price.

## Shopper classification

- Did not reach SRP → not a shopper  
- Reached SRP → shopper  
- Reached SL → active shopper  
- Txn → converted shopper  

| Metric | Formula |
|--------|---------|
| Shopper Rate | SRP / Landing sessions × 100 |
| Shopper CR | Txns / SRP (= app CR) |
| Landing-to-Txn CR | Txns / Landing sessions × 100 |

## Expected flat schema

One row per `dt × acquisition_channel × landing_page_type`: landing_sessions, srp_sessions, downstream funnel, txns, seats, GMV, discount/reddeal.

Rules: monotonic funnel; last-click channel; categorize URLs (no raw URL explosion); keep rows with srp_sessions = 0.

## Analysis patterns

1. Channel quality — shopper rate  
2. Channel CR — landing-to-txn and shopper CR  
3. Mix-shift expected CR vs actual  
4. Landing page effectiveness  
5. Shopper spike — channel then landing page  

Enhances `/dod`, `/wow-day`, `/wow-week`, `/mom` with "why is traffic different?"
