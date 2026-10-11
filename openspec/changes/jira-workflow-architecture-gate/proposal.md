## Why

The Jira workflow currently treats assignment, `In Progress`, and branch setup as sufficient preparation for implementation. That is unsafe because this repository now has distinct planning boundaries for Power BI reports, Fabric development, and troubleshooting, and each requires a different durable record and handoff.

## What Changes

- Add a mandatory, user-selected routing gate after Jira and branch setup with exactly four top-level choices: **Bug**, **Report Development Story**, **Fabric Development**, and **Other**.
- Use Jira summary and description as context for the prompt, but never infer or silently select the work category.
- Add report-story sub-routing for new reports/dashboards, existing report changes, model-only work, and report publishing/management.
- Route new report work through the established `brief.md` -> `powerbi-architect` -> canonical specification -> explicit implementation flow.
- Use OpenSpec as the active planning record for Fabric development because Fabric has orchestration agents but no separate architect/developer pair.
- Route Bug and investigative Other work through the existing `TROUBLESHOOTING.md` lifecycle, including reusable guidance updates after resolution.
- After a confirmed root cause, use a lightweight fix gate (surface plus two blast-radius triggers: rename/removal with dependents, or a new object/structural change; user confirms) instead of re-running full routing; surgical fixes need no new planning record.
- Define distinct record roles: `MEMORY.md` for durable vendor-neutral truths, route-owned recovery records (Power BI `specs/<JIRA>-<slug>/`, OpenSpec `<JIRA>-<slug>` change, `TROUBLESHOOTING.md` section) for planned work and progress, and the local `SESSION_RESUME.md` as a non-essential convenience.
- Pause non-investigative Other work for a user-directed workflow instead of guessing.
- Make planning state, handoff location, and implementation authorization explicit; completion of planning never starts implementation automatically.
- Require a local, gitignored `SESSION_RESUME.md` to be updated after every commit performed by the workflow so the current handoff, validation state, and next resume point survive interruption; it is never staged. Durable knowledge stays in tracked `MEMORY.md`.
- Untrack `SESSION_RESUME.md` and adapt `scripts/end-session.ps1` to stage only publishable handoff files and not fail when only the local handoff changed.
- Preserve the existing Jira assignment, status-transition, branch-guard, and Jira-comment behavior.

## Capabilities

### New Capabilities

- `devops/jira-workflow-architecture-gate`: Defines mandatory user-selected Jira routing, downstream planning records, troubleshooting guidance capture, and explicit implementation handoff.

### Modified Capabilities

- None.

## Impact

- Affected workflow documentation and agent orchestration under `plugins/devops/`.
- Power BI report-planning and architect handoff documentation under `plugins/powerbi/`.
- Fabric planning and implementation orchestration under `plugins/fabric/`.
- `TROUBLESHOOTING.md` and the troubleshooting workflow's shared guidance contract.
- `SESSION_RESUME.md` (now local and gitignored), `MEMORY.md`, `.gitignore`, and the repository's commit handoff convention.
- `scripts/end-session.ps1` and its tests.
- OpenSpec changes in repositories performing Fabric development.
- No Jira API contract changes; the existing Jira MCP operations remain unchanged.
