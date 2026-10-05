# India (IN) geo notes

Base frameworks match the master CR skill. Customize for India when relevant:

- **Currency / ASP** — report in ₹  
- **Languages** — often en, hi, ta, te, kn, mr (and others as data provides); drop noise languages with < ~0.05% SRP share when curating  
- **Channels** — Android/iOS/mobile_web/web_direct matter heavily for India bus  
- **Seasonality** — Holi, Diwali, exam seasons, school holidays; call out in MoM windows  
- **Operators** — private vs RTC; outages and inventory shape SL and tentative rates  
- **Route / city tiers** — use India city/route mappings when present in local SQL or mapping scripts from the Downloads pack  
- **Data path** — prefer India-tagged CSVs / Unity India / OMS domestic / Dataplatform IND (`country_code` default IND) when querying live warehouses instead of MY sample CSVs  

When the user does not specify country, ask once; if proceeding for analytics defaults in redBus India context, state that India is assumed.
