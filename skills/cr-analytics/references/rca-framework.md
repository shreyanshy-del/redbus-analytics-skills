# RCA frameworks

## CR causality

`CR = Transactions / SRP Sessions`

- Transactions ↓ → CR ↓
- SRP ↑ without proportional txns → CR ↓

### Tree

```
CR dropped?
├── SRP Sessions INCREASING?
│   └── Oops also rising? → early failures absorbing traffic (suppresses SL + downstream)
└── Transactions IMPACTED?
    └── Find drop step:
        1. SRP → SL          (Oops + SL Failure)
        2. SL → Cust Info    (availability / SL quality)
        3. Cust Info → Create Order
        4. Create Order → Order Info  (Tentative Error)
        5. Order Info → Txn  (Payment Drop)
```

Use for alerts, weekly failure attribution (rank Oops / SL Fail / Tentative / Payment Drop by WoW delta), and daily narratives (worst step; if SRP→SL, call out Oops; if sessions spike, name user_type / language).

## Causation vs correlation

| Signal | Type |
|--------|------|
| Mix shift to guest/new | Correlation |
| More short-DBD (0–1 day) | Correlation |
| Aligns with weekday baseline | Correlation |
| Festival / peak DOJ exploratory traffic | Correlation |
| Oops / SL / Tentative beyond norm | Causation |
| Funnel break not explained by mix | Causation |
| Single platform or user_type vs own baseline | Causation |
| Mix-adjusted expected ≈ actual | Correlation |
| Mix-adjusted expected > actual | Causation (residual) |

```
Expected CR = Σ (segment_share_today × segment_CR_last_week)
gap ≤ ~0.3pp → structural; residual gap → escalate as operational
```

Combined flow: (1) mix → Expected CR, (2) weekday baseline, (3) error rates, (4) residual unknown (external / deploy / data).

Until long history exists, structural vs operational labels from WoW same-day are **indicative**.

## Shopper spike hierarchy

When SRP sessions jump:

1. **Shopper MIX** — region, DBD, user_type, channel, language  
   - Guest + sameday → expect lower CR  
   - Returning + advance DBD → organic demand; look elsewhere for CR drivers  
2. **TRANSACTION MIX** — ASP ↓, RedDeal% ↑, Discount% ↑ → promo/deal-seekers  
3. **FUNNEL & ERRORS** — SL Fail, Tentative/Oops, Payment Drop, step breakdown  

## Segment isolation rule

If a segment's CR delta ≥ **1.5×** overall delta → name that segment.  
If splits are uniform → say nothing isolated in product dimensions; point to tech logs / deploy history.
