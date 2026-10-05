# Lessons learned (agent rules)

Condensed from CR Analytics `LESSONS_LEARNED.md`.

1. **No lazy "go check X"** — If dimension data exists, run the cut and name the culprit or say nothing visible. Never ship action text that only says "compare by user type…".

2. **Document geo coverage for derived dims** — e.g. route_type needs Source/Destination; don't silently imply all countries.

3. **Full chain for new dimensions** — engine → API → filter-options → filter state → buildFilterParams → dimension tab. Vectorize; never `apply(axis=1)` on multi-million row frames.

4. **Invisible filter ≠ bad UI** — Restart/server/data pipeline first before ripping out frontend wiring.

5. **Don't hardcode dim lists in filter-options** — Iterate available slices dims (or keep one source of truth).

6. **Verify seats column semantics** — per-row sum vs repeated daily `.first()`. Comments lie; inspect CSV.

7. **Validate offline before dashboard** — Direct Python check of KPIs. Never debug-print into `--reload`-watched files (infinite reload).

## Template for new lessons

```
## #N — Short description
**Rule:** one-sentence principle
**Avoid:** concrete anti-pattern
```
