# Redbus Conversion Analyser - Complete File Usage Guide

## 1) Goal of this repository

This repository is a blueprint for building a **Conversion Rate (CR) Analyzer** for Redbus booking funnel diagnostics, where:

- `CR = Transactions / SRP Sessions`
- Root cause analysis focuses on **funnel leakage**, **error spikes**, and **traffic/mix shifts**
- The backend serves both:
  - deterministic analytics endpoints (KPIs, funnel, trends, alerts, summaries)
  - AI-assisted RCA using structured tool calls

This guide explains **how every file in this folder is used** to build, run, and evolve that analyzer.

---

## 2) End-to-end architecture flow

### Step A - Define business logic and RCA rules

- `SKILLS.md`
- `LESSONS_LEARNED.md`
- `skills/**/*.md`
- `skills/geos/india/SKILLS_IN.md`

These files define:

- funnel semantics
- RCA decision trees (causatimetric formulas on vs correlation)
- operational best practices and guardrails
- reusable analyst prompts/skills

### Step B - Prepare and ingest data

- `backend/data_connector.py`
- `backend/csv_data_engine.py`
- `backend/slices_engine.py`
- `backend/route_type_mapping.py`
- `funnel_dimensions/*.sql`

These files extract and normalize:

- main aggregate funnel data (`dt x user_type x platform x language x country`)
- slices drilldown data (`doi x route x dimension`)
- derived dimensions like `route_type`

### Step C - Expose analytics APIs

- `backend/main.py`
- `backend/requirements.txt`

These files expose the API layer and orchestration:

- load engines
- route requests to the right engine
- provide period comparison, alerts, weekly summaries, and filter options

### Step D - Enable AI-assisted RCA

- `backend/main.py` (chat endpoint + tool loop)
- `SKILLS.md` and geo skill files (context payload)

The AI layer uses deterministic tool outputs to produce explainable narratives.

### Step E - Validate and harden

- `backend/validate_numbers.py`
- `backend/debug_seats.py`
- `LESSONS_LEARNED.md`

These files validate metric parity and prevent repeated data/logic mistakes.

### Step F - Future production migration

- `backend/iceberg_fetcher.py`

This is the migration template to replace CSV/mock with real Iceberg warehouse access.

---

## 3) File-by-file usage map (all files)

## Root-level files

### `README.md`

Current file is still the default GitLab template.  
**How used:** replace with project-specific setup and usage instructions (currently not functional documentation).

### `SKILLS.md`

Master business + product operating document.  
**How used in analyzer:**

- source of truth for metric definitions (CR, ASP, Oops, SL failure, Tentative error, Payment drop)
- RCA logic for daily/weekly diagnosis
- expected dashboard modules and endpoint contracts
- informs team and AI prompt design

### `LESSONS_LEARNED.md`

Postmortem playbook capturing prior mistakes and fixes.  
**How used in analyzer:**

- prevents regressions in data logic (e.g., seats aggregation mistakes)
- enforces operational discipline (dimension checks before recommendations, restart/reload validation)
- acts as implementation QA checklist for future changes

---

## Skills folder

### `skills/README.md`

Explains skill folder structure and intent.  
**How used:** onboarding doc for analysts/devs to maintain skill-driven workflows.

### `skills/dod-analysis/SKILL.md`

DoD template (`/dod`).  
**How used:** should be completed to standardize daily “yesterday vs day-before” CR checks.

### `skills/wow-same-day/SKILL.md`

WoW same-day template (`/wow-day`).  
**How used:** compare Monday vs Monday, etc., to remove weekday bias in incident diagnosis.

### `skills/wow-7day/SKILL.md`

WoW 7-day template (`/wow-week`).  
**How used:** smoother weekly trend diagnosis (noise reduction from daily volatility).

### `skills/mom-analysis/SKILL.md`

MoM template (`/mom`).  
**How used:** monthly trajectory and seasonality-aware comparison logic.

### `skills/web-analytics/SKILL.md`

Detailed web acquisition/landing/shopper taxonomy.  
**How used in analyzer roadmap:**

- extends current app-funnel model with pre-SRP acquisition layer
- enables channel-quality and landing-page-quality attribution
- defines future schema for integrated web-to-booking funnel

### `skills/geos/india/SKILLS_IN.md`

India-specific localized copy of master skills.  
**How used:** geo customization layer for market-specific thresholds, examples, and notes while preserving shared core logic.

---

## Backend files

### `backend/requirements.txt`

Dependency contract.  
**How used:** installs runtime stack:

- FastAPI/Uvicorn for APIs
- pandas/numpy for analytics
- anthropic for AI chat
- dotenv for env loading
- sqlalchemy for DB mode

### `backend/main.py`

Primary orchestrator and API server.  
**How used in analyzer:**

- loads engines via `_load_engines()` with source priority
- runs periodic auto-reload (`DATA_RELOAD_INTERVAL`)
- routes filters and dimensions between main engine and slices engine
- exposes all analytics APIs:
  - `/api/meta`
  - `/api/filter-options`
  - `/api/kpis`, `/api/kpis-l1`
  - `/api/cr-trend`
  - `/api/funnel`
  - `/api/dimension/{dim}`
  - `/api/transaction-mix`
  - `/api/failures`
  - `/api/insights`
  - `/api/period-comparison`
  - `/api/wow-daily-table`
  - `/api/summary`
  - `/api/seats`
  - `/api/alerts`
  - `/api/geos`, `/api/skills`, `/api/reload-data`
- AI assistant:
  - `/api/chat` with tool-use loop (up to 8 rounds)
  - `/api/chat/{session_id}` delete for memory reset
- supports skills content serving and webhook auto-sync

This file is the “control plane” of the entire conversion analyzer.

### `backend/data_connector.py`

Unified source adapter for ingestion.  
**How used in analyzer:**

- provides source fallback chain:
  1. S3 Parquet
  2. MSSQL
  3. DB connection string (SQLAlchemy)
  4. CSV fallback
- normalizes source-specific schemas into engine-compatible columns
- supports geo filtering and country mapping
- separates `load_main_data()` and `load_slices_data()` contracts

This file is critical for environment portability (local, EC2, DB, S3).

### `backend/csv_data_engine.py`

Main analytics engine over aggregated data.  
**How used in analyzer:**

- normalizes column variants and date formats
- computes derived metrics (`search_cr`, `error_rate`, `payment_proxy_rate`, `sl_failure_rate`, `oops_rate`, `asp`, `seats_lost`)
- provides deterministic analysis methods:
  - `get_kpis`
  - `get_cr_trend`
  - `get_funnel`
  - `get_dimension_breakdown`
  - `get_failure_metrics`
  - `get_auto_insights`
  - `get_seats_impact`
  - `compare_periods`
- anomaly detection over error spikes for highlighted periods

This is the primary calculation engine used by most APIs.

### `backend/slices_engine.py`

Granular drilldown engine over exploded route-level slices.  
**How used in analyzer:**

- loads high-granularity slices data
- handles dimension-specific semantics (especially DBD where SRP can be sparse and SL is used as denominator)
- derives `route_type` using source/destination city mapping
- computes L1 analytics and filter options for:
  - `region`
  - `dbd`
  - `route_type`
  - `channel` (and other available dimensions)
- provides methods for breakdowns, trends, funnel, KPI mode, and transaction mix

This engine enables “why” analysis at segment level.

### `backend/route_type_mapping.py`

Static lookup + classification logic for `route_type`.  
**How used in analyzer:**

- maintains `CITY_CATEGORY` mapping across countries
- applies hierarchy (leisure/pilgrim priority, then tier ranking)
- exposes `get_route_type()` for route classification
- includes placeholder `CITY_PAIR_DISTANCE` and `get_route_distance()` for future distance-based logic

It is consumed by `slices_engine.py` during load-time derivation.

### `backend/mock_data.py`

Simulation engine for demo/non-data environments.  
**How used in analyzer:**

- generates synthetic 90-day funnel data with realistic drop + recovery behavior
- supports all core API method contracts so backend works without real datasets
- useful for UI/API development before data pipeline readiness

### `backend/iceberg_fetcher.py`

Template for real warehouse migration.  
**How used in analyzer roadmap:**

- defines expected method interface compatible with `MockDataEngine` usage in `main.py`
- outlines connector options (Spark/PyIceberg/Trino/Athena)
- placeholder methods to replace CSV/mock with production Iceberg tables

### `backend/validate_numbers.py`

Audit script for metric parity with reference reports.  
**How used in analyzer:**

- compares SRP, txn, CR, GMV, channel splits against known benchmark dates
- quickly surfaces definition mismatches or duplicate-count issues
- should be run after logic/schema changes

### `backend/debug_seats.py`

Focused debugging utility for seat aggregation issues.  
**How used in analyzer:**

- inspects row-level `total_seats` behavior for a specific day
- helps detect incorrect dedupe vs sum assumptions
- supports rapid verification after bug fixes

---

## Funnel SQL files

These SQL files are **upstream data extraction templates**.  
They build funnel-stage datasets by dimension from event tables:

- `search_details`
- `search_route_details`
- `seat_layout_details`
- `cust_info_details`
- `create_order_details`
- `order_info_details`
- `make_payment_details`
- `confirm_order_details`

Common pattern in all SQL files:

- dedupe sessions/events per stage
- bridge session to route via `search_route_details`
- aggregate funnel throughput + confirmations
- compute conversion (`confirm_cr_pct`)

### `funnel_dimensions/README.md`

Instructions and assumptions for funnel-by-dimension SQL framework.  
**How used:** setup checklist for base table, filters, and mapping substitutions.

### `funnel_dimensions/01_route_level.sql`

Route-level funnel (`src_id x dest_id`).  
**Use:** detect route-specific conversion and drop pockets.

### `funnel_dimensions/02_dbd_level.sql`

DBD-based funnel using `DATE_DIFF` between search date and DOJ.  
**Use:** intent-timing analysis (last-minute vs advance bookings).

### `funnel_dimensions/03_channel_wise.sql`

Channel-level funnel.  
**Use:** platform/acquisition path diagnostics.

### `funnel_dimensions/04_region_wise.sql`

Region-level funnel via city-region mapping table.  
**Use:** geo attribution for CR shifts and anomalies.

### `funnel_dimensions/05_vernac_level.sql`

Language-level funnel.  
**Use:** vernacular/market-segment conversion behavior.

### `funnel_dimensions/06_operator_level.sql`

Operator-level funnel (`operator_id`).  
**Use:** supply/operator-specific conversion bottlenecks.

### `funnel_dimensions/07_primo_non_primo.sql`

Primo vs non-primo segmentation.  
**Use:** premium inventory performance split.

### `funnel_dimensions/08_gds_level.sql`

GDS segmentation.  
**Use:** distribution-system quality/comparison diagnostics.

### `funnel_dimensions/09_lmb_non_lmb.sql`

LMB vs non-LMB segmentation (derived from DOJ proximity by default).  
**Use:** late-minute booking pressure and contention behavior.

### `funnel_dimensions/10_organic_inorganic.sql`

Traffic-source split using source/UTM logic.  
**Use:** organic vs paid/other intent-quality and conversion comparison.

### `funnel_dimensions/11_gender.sql`

Gender segmentation (`is_female_user`).  
**Use:** demographic variation in funnel performance.

### `funnel_dimensions/12_user_type.sql`

User-type segmentation (`new/returning/guest`).  
**Use:** core mix-shift attribution and RCA baseline.

---

## 4) How these files combine into the final Redbus Conversion Analyzer

## Phase 1 - Baseline deploy (current usable path)

1. Install dependencies from `backend/requirements.txt`.
2. Configure env (`CSV_DATA_PATH`, optionally `SLICES_DATA_PATH`, `ANTHROPIC_API_KEY`).
3. Start FastAPI server using `backend/main.py`.
4. Use endpoints for KPI cards, trends, funnel, insights, alerts, weekly summary.
5. Use `/api/chat` for AI narratives based on tool outputs.

## Phase 2 - Data quality and trust

1. Run `backend/validate_numbers.py` after every metric logic change.
2. Use `backend/debug_seats.py` for aggregation sanity checks.
3. Update guardrails in `LESSONS_LEARNED.md`.

## Phase 3 - Dimension and geo maturity

1. Expand/maintain `backend/route_type_mapping.py`.
2. Add geo-specific analyst logic under `skills/geos/`*.
3. Keep master/geo skills aligned (`SKILLS.md`, `SKILLS_IN.md`).

## Phase 4 - Warehouse-first production

1. Operationalize SQL templates in `funnel_dimensions/*.sql`.
2. Materialize daily aggregated and slices datasets.
3. Replace CSV-mode internals using `backend/iceberg_fetcher.py`.
4. Keep API contracts stable in `main.py` so frontend and AI remain unchanged.

---

## 5) Practical responsibility split by file group

- **Business rules & RCA policy:** `SKILLS.md`, `LESSONS_LEARNED.md`, `skills/`*
- **Data ingestion adapters:** `backend/data_connector.py`
- **Primary metrics engine:** `backend/csv_data_engine.py`
- **Drilldown engine:** `backend/slices_engine.py`
- **Dimension derivation dictionary:** `backend/route_type_mapping.py`
- **API + orchestration + AI:** `backend/main.py`
- **Validation/debug operations:** `backend/validate_numbers.py`, `backend/debug_seats.py`
- **Production migration template:** `backend/iceberg_fetcher.py`
- **Warehouse extraction templates:** `funnel_dimensions/*.sql`

---

## 6) Important implementation notes for Redbus rollout

1. Keep **main CSV** and **slices CSV** semantics separate.
  Slices are intentionally exploded; compare rates and shares, not raw totals, against main.
2. Preserve API contracts in `main.py` while changing backend source internals.
  This allows frontend/AI to stay stable through migrations.
3. Treat `LESSONS_LEARNED.md` as a release checklist, not just history.
4. Complete TODO placeholders in skill templates before operationalizing analyst workflows.
5. Prioritize finishing upstream SQL + warehouse integration for long-term reliability over growing CSV complexity.

---

## 7) Current gaps visible from this folder

- Root `README.md` is not yet project-specific.
- Several skill templates are still TODO placeholders.
- `iceberg_fetcher.py` is scaffold-only (not connected).
- `funnel_dimensions/*.sql` are templates and require catalog/table validation before production use.

These are the highest-impact completion tasks to convert this repo from strong prototype to production-grade Redbus CR Analyzer.