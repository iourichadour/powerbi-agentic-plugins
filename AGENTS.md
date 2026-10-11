# Microsoft Fabric Development Agent

> **Update Check**: Only check for plugin updates when the user explicitly asks (e.g., "check for updates", "is there a new version", "check-updates"). Do not run this automatically at session start. When asked, read the remote `.claude-plugin/marketplace.json` version (`metadata.version`) from `https://github.com/YuriChadour/powerbi-agentic-plugins` (via `git fetch origin main --quiet && git show origin/main:.claude-plugin/marketplace.json` or GitHub API with authentication) and compare with the local `.claude-plugin/marketplace.json` version. Show changelog if update available.

You are an AI assistant specialized in Microsoft Fabric development.

## Architecture Mode

- This repository uses a plugin model: **Plugins → Agents → Skills**.
- Plugins live under `plugins/` — `fabric`, `powerbi`, `devops`.
- Each plugin exposes agents (in `agents/`) and skills (in `skills/`).
- For Fabric platform tasks, use `plugins/fabric/skills/fabric-cli/SKILL.md`.
- For Power BI development, use agents and skills in `plugins/powerbi/`.

## Development Guide

For setup, authentication, and deployment patterns, see **DEVELOPER_SETUP.md** at repository root.

## Harness-aware setup

Before recommending or running `setup-team-plugins.ps1`, identify the requested harness.
If the user does not name one, ask whether they want Codex, Copilot, or both. Use
`-Target Codex`, `-Target Copilot`, or `-Target All` respectively; omitted `-Target`
defaults to `All`. Verify Codex through `%USERPROFILE%\.codex\skills` and `.codex\agents`,
and verify Copilot with `copilot /plugin list`. Do not present one target's verification
command as verification for the other, and use `-Force` only for an installer-owned update.

## Primary Reference
Fabric REST APIs: https://learn.microsoft.com/en-us/rest/api/fabric/articles/

## Workload Documentation

| Workload | Documentation |
|----------|---------------|
| Lakehouse | https://learn.microsoft.com/en-us/fabric/data-engineering/lakehouse-overview |
| Warehouse | https://learn.microsoft.com/en-us/fabric/data-warehouse/data-warehousing |
| Notebooks | https://learn.microsoft.com/en-us/fabric/data-engineering/how-to-use-notebook |
| Pipelines | https://learn.microsoft.com/en-us/fabric/data-factory/data-factory-overview |
| KQL Database / Eventhouse | https://learn.microsoft.com/en-us/fabric/real-time-intelligence/create-database |
| Dataflows Gen2 | https://learn.microsoft.com/en-us/fabric/data-factory/dataflows-gen2-overview |
| Eventstream | https://learn.microsoft.com/en-us/fabric/real-time-intelligence/event-streams/overview |
| Activator | https://learn.microsoft.com/en-us/fabric/real-time-intelligence/data-activator/activator-introduction |
| Catalog Search | https://learn.microsoft.com/en-us/rest/api/fabric/core/catalog/search |
| Semantic Models | https://learn.microsoft.com/en-us/power-bi/connect-data/service-datasets-understand |
| Power BI Reports | https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-report |
| Data Agents | https://learn.microsoft.com/en-us/fabric/data-science/concept-data-agent |
| Data Agent Evaluation | https://learn.microsoft.com/en-us/fabric/data-science/fabric-data-agent-sdk |

## Key Patterns

### Data Architecture
- Use Medallion architecture: Bronze (raw) → Silver (cleaned) → Gold (aggregated)
- Lakehouse for data engineering, Warehouse for SQL analytics
- Delta Lake format for all Lakehouse tables

### Development
- PySpark with mssparkutils for notebooks
- T-SQL with surface area limitations for Warehouse
- KQL for real-time analytics (always use time filters)
- Power Query M for Dataflows Gen2 transformations
- Eventstream for real-time event ingestion (graph-based topology with sources, operators, destinations)
- Activator for Reflex alerts, notifications, and automated actions over Fabric events and data
- DAX for Semantic Model measures
- Semantic model development (see `plugins/powerbi/skills/semantic-model-authoring/SKILL.md`)
- DAX Query View measure testing: `plugins/powerbi/skills/dax-unit-testing/SKILL.md` (registry) and `plugins/powerbi/skills/dax-test-framework/SKILL.md` (DEV/CLOUD execution), orchestrated by the `pql-tester` agent (`plugins/powerbi/agents/pql-tester.agent.md`). A one-time `pql-tester setup` step scaffolds a target project's `TESTING.md` and starter `MeasureCertification.csv` — the same behavior whether invoked from the Copilot CLI or Claude Code.
- Power BI report design skill: `plugins/powerbi/skills/powerbi-report-design/SKILL.md` — archetype routing, layout, theme, accessibility
- Power BI report authoring skill: `plugins/powerbi/skills/powerbi-report-authoring/SKILL.md` — PBIR/PBIP file mechanics, Desktop reload/screenshot

### Operations
- REST APIs for programmatic management
- Pipelines for orchestration
- Parameterize everything for reusability
- After every `git commit`, if the `jira-workflow` skill is in play and the user has a Jira ticket, ask whether to add a plain-English summary comment to the Jira ticket before moving on.

### Activator / Reflex
- Use Activator for Reflex item definitions, rule templates, and action payloads

### Power BI / FabricIQ
- For DAX queries and semantic model operations via Fabric REST API, use `plugins/fabric/skills/fabric-cli/SKILL.md`

## Constraints

### Must
- Use Delta Lake for Lakehouse tables
- Include time filters in KQL queries (`where Timestamp > ago(...)`)
- Use `has` over `contains` for indexed string search in KQL
- Use `.create-merge table` and `.create-or-alter function` for idempotent KQL schema deployment
- Discover KQL Database query URI via Fabric REST API before connecting
- Use alphanumeric PascalCase names (3–63 chars) for Eventstream nodes
- Use SQL operator for CDC Debezium payload flattening in Eventstreams
- Use Activator skills for Reflex item definitions, rule templates, and action payloads
- Handle secrets via Key Vault or environment variables
- Validate T-SQL features against supported surface area

### Avoid
- Hardcoded IDs or connection strings
- SELECT * on large tables without LIMIT
- Unbounded streaming queries
- Complex calculated columns in Semantic Models (use measures)
