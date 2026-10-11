## Why

`openspec-bridge`'s decision rule tells users **not** to adopt OpenSpec tracking for specs that
are "implemented and stable" or "one-shot" — but that is exactly the situation for every
`powerbi-architect`-authored spec sitting in a repo's `specs/` folder today (e.g. all 7 flat specs
in `Glasslake-1/specs/`): completed, unarchived, with no history or tracking. The rule conflates
two different questions — "should this stay open as an actively-iterated change?" vs. "should this
completed work get a one-time backfilled archive record?" — and only answers the first, leaving
the actual use case (backfilling history for already-done work) with no supported workflow.

## What Changes

- Replace the bridge's two-outcome decision table (`Yes`/`No` for adopting *ongoing* tracking)
  with a decision rule that only asks whether a spec is **done**: **Backfill now** (implemented,
  stable, not yet archived — the only case this skill acts on) or **Skip** (still in progress, or
  disposable/declined). Drop the "adopt ongoing tracking" outcome entirely — this skill is a
  supplement for recording finished work, not a parallel change-management system to run
  alongside a spec that's still being actively revised in place.
- Replace the bridge's single "adopt tracking" workflow (which scaffolded a change and left it
  open) with a "backfill archive history for an already-completed spec" workflow: maps the spec's
  sections into proposal/specs/design, scaffolds `tasks.md` with every checkbox pre-checked `[x]`
  (work is already done), then immediately hands off to the repo's `openspec-archive-change`
  skill so the spec lands directly in `openspec/changes/archive/YYYY-MM-DD-<name>/` with its delta
  synced into `openspec/specs/` — never left open as an in-progress change.
- Cross-check the new backfill handoff against `openspec-archive-change`'s and
  `openspec-sync-specs`'s actual contract (artifact paths via `openspec status --json`,
  sync-before-move gating, date-prefixed archive folder naming) so the immediate-archive path
  doesn't assume a bare `openspec archive` CLI command or bypass the sync/validation gate.
- Dogfood the fixed backfill workflow against one real completed spec in an external repo
  (`Glasslake-1/specs/Python-MCP-DAX-Test-Framework.spec.md`) to prove the mapping end-to-end,
  scoped to that single spec for this change; the remaining specs in that repo are an explicit
  follow-up, not part of this change.

## Capabilities

### New Capabilities
- `spec-lifecycle/openspec-bridge`: requirements for the `openspec-bridge` skill's decision rule
  (backfill vs. skip) and its single backfill workflow, including the immediate-archive handoff
  contract.

### Modified Capabilities
- None — `spec-lifecycle/openspec-bridge` does not exist yet under `openspec/specs/`; this is the
  first spec for this capability.

## Impact

- `plugins/spec-lifecycle/skills/openspec-bridge/SKILL.md` — decision rule and workflow sections
  rewritten/extended.
- No changes to `plugins/powerbi/*` (including `powerbi-architect.agent.md`) — explicit constraint
  to avoid upstream merge-conflict risk against `skills-for-fabric`.
- External repo `C:\Development\Glasslake-1` — dogfooding target only; not part of this repo's
  source tree, changes there are verification, not deliverables of this change.
