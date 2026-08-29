# Power BI

Power BI development plugin that connects AI agents to semantic models, reports, and Fabric workspaces — enabling design, development, and deployment of complete Power BI solutions.

## What it does

Activated when a user needs to design, build, or maintain Power BI solutions. Covers the full development lifecycle from architecture and data modeling to report authoring, DAX optimization, deployment to Microsoft Fabric, and **optimization for Report Copilot pane**.

|  |  |
|--|--|
| Semantic model development | "Create a star schema model from this CSV data" |
| DAX measures | "Add a Year-over-Year growth measure to the Sales table" |
| Direct Lake models | "Set up a Direct Lake semantic model pointing to my lakehouse tables" |
| DAX performance | "Why is this measure slow? Optimize it for me" |
| Solution architecture | "Design a semantic model spec for my inventory data" |
| Deployment | "Deploy the semantic model to the Production workspace" |
| **Report Copilot optimization** | **"Optimize my report so Copilot answers questions using existing visuals"** |

## Agents

### `powerbi-developer`

Activated when a user needs to implement Power BI solutions — creating and editing semantic models, writing and optimizing DAX, building reports in PBIR format, and deploying to Fabric workspaces. Uses the `semantic-model-authoring`, `powerbi-report-authoring`, and `fabric-cli` skills.

### Sample install prompt

```text
Use @setup-team-plugins.ps1 -PluginName powerbi to install only the Power BI plugin.
```

### `powerbi-architect`

Activated when a user needs to design a Power BI solution before implementation. Analyzes data sources, designs star schemas, and produces detailed spec documents (`specs/*.spec.md`) for the `powerbi-developer` agent to execute. Does not implement — only designs.

## Skills

### `semantic-model-authoring`

Activated for any semantic model operation — creating or editing tables, measures, relationships, and hierarchies; writing DAX; configuring Direct Lake partitions; deploying models to Fabric; and working with TMDL files and PBIP projects.

### `powerbi-report-authoring`

Activated for any report operation — creating or editing Power BI reports in PBIR format, configuring visuals and pages, applying themes, rebinding reports to different semantic models, and deploying reports to Fabric workspaces.

### `powerbi-report-design`

Activated before PBIR files are written — commits a design identity (tone + signature), routes pages to the right archetype, and applies cross-cutting design principles (color, typography, layout, accessibility). Produces a `Design Brief:` contract for `powerbi-report-authoring` to implement.

### `powerbi-report-planning`

Activated for end-to-end new report/dashboard requests — guides requirements gathering, page planning, and design direction through to an approved, lockable report spec, then continues into implementation.

### `powerbi-report-management`

Activated for Fabric REST CRUD on report workspace items — create, get/download, update, list, and delete report definitions via `az rest` against the Fabric REST API.

### `check-updates`

Checks for skills-for-fabric marketplace updates. Only runs when the user explicitly asks (e.g., "check for updates", "is there a new version") — never automatically at session start.

### `prep-powerbi-for-report-copilot`

Activated when optimizing Power BI reports and semantic models for Report Copilot pane readiness. Provides a complete 5-step workflow: report usage inventory, AI data schema design, AI instructions authoring, Answer Pack page strategy, and test automation. Helps teams ensure Copilot answers questions using existing visuals instead of generating new ones, protects sensitive fields from Copilot reasoning, and standardizes Copilot behavior across the organization.

### `dax-data-quality`

Activated for building a metadata-driven Power BI Data Quality framework — Power Query row-level checks plus DAX measures for a rules registry and exceptions view.

### `sql-data-quality`

Activated for building a metadata-driven SQL Server Data Quality framework — T-SQL audit views with per-column DQ flags, surfaced to Power BI over DirectQuery.

### `tmdl`

Activated for direct TMDL file authoring and BIM-to-TMDL conversion in PBIP projects — syntax, indentation, and migration guidance.

### `skill-merge-planner`

Activated when comparing this repo's skills against an external/reference skill collection (e.g. `skills-for-fabric-1`) to check for drift, rate authoring quality, and generate a phased merge plan. Scores matched skill pairs against a 7-dimension Skill-authoring quality rubric, identifies cost-effective content to graft from either side, and writes a durable plan document under `plans/`. Does not execute the plan — file copies/merges/renames are a separate, user-approved step.

## MCP server

The `powerbi-modeling-mcp` server provides a direct connection to a live Power BI semantic model running in Power BI Desktop. It exposes tools for querying model metadata, running DAX queries, and applying model changes — enabling agents to work with the model interactively without editing TMDL files manually.

The MCP server runs in-process with Power BI Desktop (requires the Analysis Services endpoint to be enabled).
