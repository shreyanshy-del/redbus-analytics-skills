# redBus Analytics Skills for Cursor

Shared Cursor Agent Skills for redBus product analytics: funnels, conversion rate, experiments, Metro, filters, pilgrim/return trips, and reusable SQL banks.

A skill is a folder with a `SKILL.md`. Cursor reads the `description` in each file and applies the skill automatically when your question matches it. For example, asking about "Metro cohort retention" triggers `metro-analytics`.

## Quick start

```bash
git clone <this-repo-url> redbus-analytics-skills
cd redbus-analytics-skills
./install.sh            # links every skill into ~/.cursor/skills
```

Restart Cursor (or open a new chat). The skills now appear under **Settings → Rules, Skills, Subagents**.

To get the latest skills later, run `git pull` in the cloned folder. The installed skills are symlinks, so there is nothing to reinstall.

Other install options:

```bash
./install.sh --copy                  # copy instead of symlink (no auto-update on git pull)
./install.sh metro-analytics cr-analytics   # install only the skills you want
./install.sh --with-rules            # also install the shared Cursor rules in rules/
```

Windows users can copy folders from `skills/` into `%USERPROFILE%\.cursor\skills\` manually.

## Prerequisites

Most skills query data through MCP servers that must already be connected in Cursor:

| MCP server | Used by |
|---|---|
| Data Platform (Iceberg / `dataplatform_mcp`) | Most skills: funnels, Metro, filters, women, pilgrim, seat images, experiments |
| OMS ClickHouse (domestic) | `toilet-cohort-analytics` |
| Athena (workgroup `Product_B2C_Intl`) | `syed-athena-queries` |

## Skill catalog

### Conversion and funnel

| Skill | Use it for |
|---|---|
| [cr-analytics](skills/cr-analytics/SKILL.md) | Conversion rate RCA: SRP → seat layout → cust info → tentative → payment → txn; DoD / WoW / MoM comparisons; Oops, tentative, and payment-drop errors |
| [women-funnel-analytics](skills/women-funnel-analytics/SKILL.md) | Women SRP vs Regular SRP, Female SVOC, single-women behaviour, women return trips |
| [return-tier-pilgrim](skills/return-tier-pilgrim/SKILL.md) | Return-trip funnel, city tiers (Tier 1/2/3), pilgrim destinations, UPSRTC |

### SRP and product features

| Skill | Use it for |
|---|---|
| [filter-usage-analytics](skills/filter-usage-analytics/SKILL.md) | SRP filter coverage: Sort & Filter, contextual chips, LMB, inline filters |
| [lmb-newbus-analytics](skills/lmb-newbus-analytics/SKILL.md) | Last-minute bus (DBD 0) and New Bus (persuasion 68) click and order share |
| [seat-bus-images](skills/seat-bus-images/SKILL.md) | Seat-utility image CTR, New Bus image coverage, route txn share |
| [toilet-cohort-analytics](skills/toilet-cohort-analytics/SKILL.md) | Toilet-on-seat-layout and toilet-amenity cohorts, pre vs post |

### Experiments and coverage

| Skill | Use it for |
|---|---|
| [experiment-coverage-analytics](skills/experiment-coverage-analytics/SKILL.md) | Insurance Lite AB, iOS addons payment-page AB, Primo operator coverage, Mobweb login funnel |

### Metro

| Skill | Use it for |
|---|---|
| [metro-analytics](skills/metro-analytics/SKILL.md) | Metro city DRR, seats, new users, cohort retention, metro → bus cross-sell |
| [metro-surface-analytics](skills/metro-surface-analytics/SKILL.md) | Metro Home, Metro Card, and Metro Sticky loads on bus buddy |

### SQL query banks

| Skill | Use it for |
|---|---|
| [query-repository](skills/query-repository/SKILL.md) | 70 saved SQL queries: pilgrim, RTC, LOB, ASP, comfort, POI, student deal, women funnel. Ask for "QUERY N" |
| [syed-athena-queries](skills/syed-athena-queries/SKILL.md) | 160 Athena saved queries (Product_B2C_Intl): bus images, RTC, Primo, cohort deals, free seats, sales. Ask for "QUERY Syed N" |

## Repository layout

```
skills/<skill-name>/
├── SKILL.md        instructions and trigger description (required)
├── references/     SQL files, lookup tables, background docs
└── scripts/        optional helper scripts
rules/              shared Cursor rules (.mdc), installed with --with-rules
docs/               background material (CR analyser guide, lessons learned)
install.sh          installer
```

## Contributing a skill

1. Create `skills/<skill-name>/SKILL.md`. The folder name must match the `name:` field in the frontmatter (lowercase, hyphens).
2. Write a specific `description` that says what the skill does and when to use it, including the words people actually type (event names, AB names, metric names). Cursor uses this text to decide when to load the skill.
3. Put long SQL or reference material in `references/` and link it from `SKILL.md`, so the main file stays short.
4. Never commit tokens, passwords, or MCP bearer keys. Read credentials from environment variables.
5. Add the skill to the catalog above and open a pull request.
