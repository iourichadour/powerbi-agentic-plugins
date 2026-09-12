# Spec Lifecycle

Optional OpenSpec bridge for `powerbi-architect`-authored specs. Adds change-tracking, status, and
archive history on top of the existing `specs/<Name>.spec.md` format — without changing where
specs live or how `powerbi-architect` authors them.

## What it does

Activated when a user wants to track, check the status of, or archive an existing Power BI spec
using OpenSpec's proposal/specs/design/tasks lifecycle.

|  |  |
|--|--|
| Adopt tracking | "Track this spec with OpenSpec" |
| Check progress | "What's the status of the Funded consolidation change?" |
| Close out | "Archive this spec now that it's implemented" |

## Skills

### `openspec-bridge`

Converts an existing `specs/<Name>.spec.md` into OpenSpec change artifacts (`proposal.md`,
`specs/<capability>/spec.md`, `design.md`, `tasks.md`), preserving all content — including any
verbatim reference implementation — instead of re-deriving it. Includes an explicit decision rule
for when OpenSpec tracking is worth adopting versus when a spec should stay a plain single file.

## Why this is a separate plugin

`plugins/powerbi/*` is kept close to the upstream `skills-for-fabric` marketplace so it can be
diffed and merged cleanly. This plugin is fully additive — it never edits `plugins/powerbi/*` — so
pulling upstream updates never conflicts with OpenSpec tracking added here.

## Precondition

The target repo must have OpenSpec initialized (`openspec init`). This plugin does not install or
configure the OpenSpec CLI itself.
