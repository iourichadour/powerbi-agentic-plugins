---
name: openspec-bridge
description: Bridges a powerbi-architect-authored specs/<Name>.spec.md into OpenSpec's change-tracking and archive lifecycle, without changing where the spec lives or how it's authored. Use when the user wants to "track this spec with OpenSpec", "archive this spec", "check the status of this spec/change", or "adopt OpenSpec tracking" for an existing single-file Power BI spec.
---

# OpenSpec Bridge for powerbi-architect Specs

## Purpose

`powerbi-architect` authors durable, single-file specs at `specs/<Name>.spec.md` (Overview /
Requirements / Design / Tasks). That format is intentionally self-contained and diagram-rich —
good for a one-shot build, weak at tracking status across repeated revisions or leaving an audit
trail when a spec is superseded or retired.

This skill does **not** change how `powerbi-architect` authors specs and does **not** replace
`specs/*.spec.md` as the content of record. It adds an optional, opt-in lifecycle layer on top,
using the [OpenSpec](https://github.com/openspec-dev/openspec) CLI's proposal → specs → design →
tasks → apply → archive workflow, for the subset of specs that actually benefit from it.

## When to use this (decision rule)

| Situation | Use OpenSpec tracking? |
|---|---|
| Spec is implemented and stable — a historical record | No — leave the single file as-is |
| One-shot build, unlikely to be revised again | No — the overhead isn't worth it |
| Spec has already been revised more than once (version bumps, corrected sections) | Yes — delta tracking and archive history pay for themselves |
| Spec is actively being iterated across multiple sessions/PRs | Yes |
| User explicitly asks to "track" or "archive" a spec | Yes |

Do not suggest migrating every spec wholesale. Ask which specific spec the user means if it's
ambiguous, and default to leaving implemented/one-shot specs untouched.

## Precondition

The target repo must already have OpenSpec initialized (`openspec init`, producing an
`openspec/` folder with `config.yaml`, `changes/`, `specs/`). If it isn't, tell the user and offer
to run `openspec init` first — do not silently skip this check.

**Naming collision to flag explicitly**: the repo's own `specs/` (powerbi-architect's single-file
specs) and OpenSpec's `openspec/specs/` (archived, delta-tracked capability specs) are two
different directories with the same base name. Never conflate them in conversation or in file
paths.

## Workflow: adopt tracking for an existing spec

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
     blocks per OpenSpec's delta-spec format
   - `Design` (architecture, diagram, components, decisions) → `design.md`'s Context / Decisions /
     Risks sections; carry the Mermaid diagram over verbatim if one exists — OpenSpec's schema
     doesn't forbid diagrams, it just doesn't prompt for one
   - Any verbatim reference code / implementation blueprint that doesn't fit the behavior-only
     `specs`/`design` rules → keep it anyway, as a clearly-labeled "Reference Implementation"
     appendix at the end of `design.md`, so nothing is lost by moving to OpenSpec's stricter
     what/how separation
   - `Tasks` → `tasks.md`, preserving the checkbox format and requirement traceability
5. Validate with `openspec validate "<name>" --strict`.
6. Add a one-line pointer at the top of the original `specs/<Name>.spec.md` noting it's now
   tracked via `openspec/changes/<name>` — do not delete or rewrite the original file's content.

## Workflow: check status / archive

- Status: `openspec status --change "<name>"` (or `--json` for programmatic use).
- Once implementation is complete and verified: follow the repo's `openspec-archive-change` skill
  (if present) or run `openspec archive "<name>"` to fold the change into `openspec/specs/` and
  close out the lifecycle.
- Report status back to the user in plain language (not raw JSON) unless they ask for the JSON.

## Explicitly out of scope

- This skill does not modify `powerbi-architect`'s agent definition or its skills. It is a
  separate, additive plugin so that syncing `plugins/powerbi/*` against the upstream
  `skills-for-fabric` marketplace stays conflict-free.
- This skill does not require every spec to move to OpenSpec — see the decision rule above.
