---
name: openspec-bridge
description: Backfills a completed powerbi-architect-authored specs/<Name>.spec.md into OpenSpec's archive lifecycle, without changing where the spec lives or how it's authored. Use when the user wants to track, archive, or check the status of an existing single-file Power BI spec.
---

# OpenSpec Bridge for powerbi-architect Specs

## Purpose

`powerbi-architect` authors durable, single-file specs at `specs/<Name>.spec.md` (Overview /
Requirements / Design / Tasks). This skill backfills a completed spec into OpenSpec's archive
history, preserving an audit trail without creating a second source of truth during active work.

This skill does **not** change how `powerbi-architect` authors specs and does **not** replace
`specs/*.spec.md` as the content of record. It adds an optional, opt-in lifecycle layer on top,
using the [OpenSpec](https://github.com/openspec-dev/openspec) CLI's proposal → specs → design →
tasks → validate → archive workflow.

## When to use this (decision rule)

| Situation | Outcome |
|---|---|
| Spec is implemented and stable, not yet archived | **Backfill now** |
| Spec is still being actively revised | **Skip** — wait until it is complete |
| Spec is trivial/disposable or the user explicitly declines tracking | **Skip** |

Classify the candidate into exactly one outcome before taking action. Do not suggest migrating
every spec wholesale. Ask which specific spec the user means if it is ambiguous. This supplement
records finished work; it does not create a parallel lifecycle for an actively edited source spec.

## Precondition

The target repo must already have OpenSpec initialized (`openspec init`, producing an
`openspec/` folder with `config.yaml`, `changes/`, `specs/`). If it isn't, tell the user and offer
to run `openspec init` first — do not silently skip this check.

**Naming collision to flag explicitly**: the repo's own `specs/` (powerbi-architect's single-file
specs) and OpenSpec's `openspec/specs/` (archived, delta-tracked capability specs) are two
different directories with the same base name. Never conflate them in conversation or in file
paths.

## Workflow: backfill archive history for an already-completed spec

1. Read the target `specs/<Name>.spec.md` in full.
2. Derive a kebab-case change name from its title (e.g. "Python DAX Test Framework" →
   `add-dax-test-framework`).
3. Run `openspec new change "<name>"`, then `openspec status --change "<name>" --json` to get the
   artifact build order for the repo's configured schema (usually `spec-driven`:
   proposal → specs → design → tasks).
4. For each required artifact, run `openspec instructions <artifact-id> --change "<name>" --json`
   and populate it **from the existing spec.md**, mapping sections instead of re-deriving them:
   - `Overview` → `proposal.md`'s Why / What Changes / Capabilities / Impact
    - `Requirements` (EARS `THE System SHALL...` acceptance criteria) → `specs/<capability>/spec.md`,
      converting each acceptance criterion into a `### Requirement` with `#### Scenario` (WHEN/THEN)
      blocks per OpenSpec's delta-spec format. For a first-time backfill, place every requirement
      under `## ADDED Requirements` because there is no existing main spec to diff against; do not
      invent MODIFIED, REMOVED, or RENAMED sections.
   - `Design` (architecture, diagram, components, decisions) → `design.md`'s Context / Decisions /
     Risks sections; carry the Mermaid diagram over verbatim if one exists — OpenSpec's schema
     doesn't forbid diagrams, it just doesn't prompt for one
   - Any verbatim reference code / implementation blueprint that doesn't fit the behavior-only
     `specs`/`design` rules → keep it anyway, as a clearly-labeled "Reference Implementation"
     appendix at the end of `design.md`, so nothing is lost by moving to OpenSpec's stricter
     what/how separation
    - `Tasks` → `tasks.md`, preserving the checkbox format and requirement traceability, but mark
      every task checkbox `[x]` because the work is already complete.
5. Run `openspec validate "<name>" --strict`.
6. Immediately invoke the repo's `openspec-archive-change` skill for `<name>` (never assume a bare
   `openspec archive` CLI call). Follow that skill's contract: sync the delta spec into
   `openspec/specs/<capability-path>/spec.md` and verify the merge before moving the change; if
   sync fails, stop and do not move the change. Archive the folder as
   `openspec/changes/archive/<YYYY-MM-DD>-<name>/`, adding today's date only when `<name>` does
   not already have a date prefix.
7. Add a one-line pointer at the top of the original `specs/<Name>.spec.md` noting it is now
   tracked via the archived OpenSpec change — do not delete or rewrite the original file's
   content.

## Workflow: check status / archive

- Status: `openspec status --change "<name>"` (or `--json` for programmatic use).
- Once implementation is complete and verified, use the backfill workflow above. The archive handoff
  must follow the repo's `openspec-archive-change` skill so delta sync and validation happen before
  the change folder is moved.
- Report status back to the user in plain language (not raw JSON) unless they ask for the JSON.

## Explicitly out of scope

- This skill does not modify `powerbi-architect`'s agent definition or its skills. It is a
  separate, additive plugin so that syncing `plugins/powerbi/*` against the upstream
  `skills-for-fabric` marketplace stays conflict-free.
- This skill does not require every spec to move to OpenSpec — see the decision rule above.
