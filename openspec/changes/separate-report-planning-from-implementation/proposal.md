## Why

`powerbi-report-planning` currently mixes business discovery, design briefing, approval, and implementation orchestration. That overlaps with the architect agent's established `specs/[Name].spec.md` workflow and the developer agent's task-and-acceptance-criteria execution contract, causing new report requests to produce generic `_brief/report-spec.md` artifacts that are not directly executable.

Artifacts for one piece of work are also scattered (`_brief/`, `plans/`, `specs/`) with no structured link between them, a fixed brief filename cannot support more than one report per repository, and the detailed design contract (`Design Brief:` YAML with `layout_contract`) never reaches the developer's specification.

The planning workflow should behave as a planning-only gate, similar to `openspec-propose`: capture business intent and an approved report brief, then hand off to the architect for the durable implementation specification.

## What Changes

- Redefine `powerbi-report-planning` as a planning-only workflow for business requirements, semantic-model discovery, report scope, page intent, design direction, dependencies, and approval. It stops after the approved brief and no longer owns model changes, PBIR authoring, validation, or publishing.
- Keep all artifacts of one work item in `specs/<JIRA>-<slug>/` (or `specs/<slug>/` without a ticket): `brief.md`, optional `mockup/`, `<Name>.spec.md`, `<Name>.plan.md`, and `<Name>.ExecutionSummary.md`. No legacy layouts are supported.
- Replace `_brief/report-spec.md` with `brief.md`, carrying front-matter (`jira`, `report`, `status`, `mockup`) and clearly not the developer execution spec.
- Accept an optional, non-gating approved HTML design mock as planning input. User sign-off on the mock counts as design approval; fields without a model counterpart become model requirements.
- Require `powerbi-architect` to consume the approved brief for new-report specs (model-only specs are exempt) and produce `<Name>.spec.md`, embedding the `Design Brief:` YAML verbatim under `Design > Report Design Contract`. EARS requirements and per-page tasks cite it, and the spec's YAML is the only authoritative design.
- Add a `Revisions` section (ADDED/MODIFIED/REMOVED) to the architect spec template so amendments, including updates from a revised mock, add tasks only for the delta.
- Have `powerbi-developer` consume the embedded Design Brief, stop on report-page tasks when it is missing, route layout changes through the architect, and derive plan and summary paths from the spec's folder.
- Document the end-to-end process in `plugins/powerbi/README.md` and the root `README.md`.
- Make the workflow verifiable in GitHub Copilot: use the current `copilot plugin list` command, validate plugin discovery separately from skill-load success, and keep all skill descriptions within Copilot's 1,024-character frontmatter limit.
- Define MCP setup readiness separately from plugin discovery: provision the pinned Power BI Modeling MCP package per user through npm, generate host-specific launch definitions, and require a bounded MCP `initialize` check before reporting the connector ready.
- Reuse an available ADOMD.NET dependency when it already satisfies the setup requirement, and install it only when discovery confirms it is missing or unusable.
- Remove installer backup artifacts whose last-write time is older than seven days, while tolerating an absent backup location and never deleting current backups.
- Make Codex MCP registration ownership-safe: update an existing installer-owned `powerbi-modeling-mcp` entry, create a missing entry, and stop with actionable remediation when a same-named entry is not installer-owned.
- Keep the MCP source declaration portable and independent of the VS Code extension; on Windows x64, project it to `node.exe` plus npm's `npx-cli.js` and the platform package so users do not depend on machine-specific extension paths or the `npx.cmd` launcher.
- Preserve `powerbi-report-design` as the visual-design specialist and `powerbi-report-authoring` as the PBIR mechanics specialist.
- Out of scope (follow-ups): HTML mock generate/refresh/ingest/bind mechanics (`design-from-html-mockup`) and a traceability validator script.

## Capabilities

### New Capabilities

- `powerbi/report-planning-boundary`: Defines the planning-only boundary, work-folder layout, approved-brief handoff, embedded design contract, and ownership contract between report planning, architecture, and implementation agents.

### Modified Capabilities

<!-- No existing OpenSpec capability currently defines this report-planning ownership contract. -->

## Impact

- `plugins/powerbi/skills/powerbi-report-planning/SKILL.md` and its template under `assets/templates/`
- `plugins/powerbi/agents/powerbi-architect.agent.md` and `.toml`
- `plugins/powerbi/agents/powerbi-developer.agent.md` and `.toml`
- `plugins/powerbi/skills/powerbi-report-authoring/SKILL.md`
- `plugins/powerbi/skills/powerbi-report-design/SKILL.md`, `references/design-brief.md`, `references/pre-flight-checklist.md`
- `plugins/powerbi/README.md` and root `README.md`
- `plugins/spec-lifecycle/README.md` and `plugins/spec-lifecycle/skills/openspec-bridge/SKILL.md`
- `setup-team-plugins.ps1`, Copilot setup documentation, and `plugins/powerbi/skills/skill-merge-planner/SKILL.md` for Copilot compatibility and MCP readiness validation
- Per-user npm cache and Node.js/npm runtime used to provision and launch the pinned Power BI Modeling MCP package; no VS Code extension installation is required
- No semantic-model, PBIR, report, or application runtime behavior changes
