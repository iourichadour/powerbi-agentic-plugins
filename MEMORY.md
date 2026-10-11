# Project Memory

> Repository memory pointer: `/memories/repo/` should reference only this
> file for durable project facts. Route records and local session state remain
> in their own records.

## Cold-start orientation

This repository is a Microsoft Fabric development plugin collection organized
as **plugins → agents → skills**. Plugins live under `plugins/` and are grouped
by workload. Shared implementation guidance lives in `common/`; durable route
records live in `openspec/changes/`, Power BI `specs/`, and
`TROUBLESHOOTING.md`.

Use the repository `AGENTS.md` for operating constraints and
`DEVELOPER_SETUP.md` for setup and deployment. Use the relevant plugin skill
before changing a Fabric, Power BI, DevOps, or migration artifact. Preserve
parameterization, externalize secrets, and validate generated definitions
before handoff.

## Durable project conventions

- Fabric work follows Bronze → Silver → Gold medallion boundaries, with Delta
  Lake tables for Lakehouse storage.
- Power BI new-report work follows approved business planning, canonical
  architecture, then explicit implementation. Existing report, semantic-model,
  and management work may use their specialist routes directly.
- Jira work is user-routed after branch setup. Jira metadata is context only;
  it is not an architectural classification.
- Investigations use one ticket section in `TROUBLESHOOTING.md`, preserve
  evidence and blockers, and extract confirmed reusable guidance separately.
- `MEMORY.md` contains only durable, vendor-neutral facts that a new harness
  can understand without conversation history. It never contains ticket
  status, active changes, branches, or next steps.

## Agent adapter conventions

- Agent adapters packaged into shared harness directories require globally
  unique names and filenames across all plugins.
- Adapter parity checks normalize line endings and trailing whitespace before
  comparing developer instructions.
- Cross-platform process launchers must resolve executable paths before process
  startup when the host cannot resolve shell shims reliably.
- User-owned profile entries are preserved; repository-managed projections may
  report stale conflicts for explicit cleanup rather than deleting unrelated
  configuration.

## Record roles and recovery

| Record | Role | Tracked |
|---|---|---|
| `MEMORY.md` | Durable, vendor-neutral project facts | yes |
| `SESSION_RESUME.md` | Last commit, validation, current state, next resume point | no |
| `TROUBLESHOOTING.md` | Investigation history and shared reusable guidance | yes |
| Route recovery record | Planned work and progress markers | yes |
| Jira | Ticket status and findings comments | external |

Route recovery records are the Power BI `specs/<JIRA>-<slug>/` folder, the
Fabric `openspec/changes/<JIRA>-<slug>/` change, or the matching ticket section
in `TROUBLESHOOTING.md`. Agents update those records as work completes;
`SESSION_RESUME.md` is convenient but never required for recovery.

## End-of-session workflow

Run `scripts/end-session.ps1` with the active OpenSpec change and the exact
publishable files. It validates OpenSpec and whitespace, reports unchecked
tasks without marking them complete, stages only `MEMORY.md`, declared files
under the active OpenSpec change, and an explicitly selected Power BI
`specs/<JIRA>-<slug>/` recovery folder, then commits. Use `-ResumePath` only
for the local handoff; it is ignored, never staged, and is updated after the
commit before push, Jira-comment, or PR handling.

If no publishable changes are staged, the script reports that no publishable
handoff changes exist and exits without committing. After the commit, offer
the Jira summary comment and PR independently according to the Jira workflow.
