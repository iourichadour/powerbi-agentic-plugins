<!-- powerbi-agentic-plugins:start -->
# Power BI Agentic Plugins (powerbi-agentic-plugins repo)

When working inside the `powerbi-agentic-plugins` workspace (or any repo built
from it), prefer its `plugins/powerbi/skills/*` skills over ad-hoc guidance.

**Report layer:**
- **powerbi-report-planning** -- guided requirements -> spec -> approval -> build for new reports/dashboards
- **powerbi-report-design** -- design identity, archetype routing, layout, color, chart selection (produces a `Design Brief:` handed to authoring)
- **powerbi-report-authoring** -- PBIR/PBIP file mechanics: pages, visuals, filters, themes, formatting, validation, Desktop reload/screenshot, BPA
- **powerbi-report-management** -- Fabric REST CRUD on report workspace items (create/get/update/delete/list)

**Semantic model layer:**
- **semantic-model-authoring** -- create/edit models, DAX, TMDL, Direct Lake, DAX performance optimization, AI/Copilot readiness, deployment

**Data quality:**
- **dax-data-quality** -- Power Query + DAX metadata-driven DQ framework for semantic models
- **sql-data-quality** -- T-SQL audit-view DQ framework with approval gate

**Other:**
- **tmdl** -- direct TMDL file authoring and BIM-to-TMDL conversion
- **prep-powerbi-for-report-copilot** -- prep reports/models for Report Copilot pane readiness
- **check-updates** -- checks for skills-for-fabric marketplace updates; only run when the user explicitly asks (never automatically)

**Agents:** `powerbi-architect` (design specs, no implementation) and
`powerbi-developer` (implementation) live under `plugins/powerbi/agents/`.
<!-- powerbi-agentic-plugins:end -->
