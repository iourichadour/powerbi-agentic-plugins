## Purpose

Defines the decision rule and workflows the `openspec-bridge` skill must follow when bridging a
`powerbi-architect`-authored `specs/<Name>.spec.md` into OpenSpec's change-tracking and archive
lifecycle, without altering how those specs are authored or where they live.

## ADDED Requirements

### Requirement: Two-outcome decision rule
The skill SHALL classify any candidate spec into exactly one of two outcomes — Backfill now or
Skip — before taking any action, and SHALL NOT treat "implemented and stable" as a reason to take
no action. The skill SHALL NOT offer an "ongoing tracking" outcome that leaves a change open
alongside a spec still being actively revised in place — that would duplicate the spec.md itself
as the source of truth during active work, adding maintenance overhead this supplement is not
meant to carry.

#### Scenario: Completed spec with no existing OpenSpec change
- **WHEN** the user asks to track, archive, or check the status of a `specs/<Name>.spec.md` that
  is already implemented and stable, and no corresponding `openspec/changes/` entry exists
- **THEN** the skill classifies it as "Backfill now" and proceeds to scaffold and immediately
  archive it, rather than declining to act

#### Scenario: Spec still in progress
- **WHEN** the user indicates a spec is still being actively revised and not yet complete
- **THEN** the skill classifies it as "Skip" and takes no OpenSpec action until the spec is done

#### Scenario: Spec the user does not want tracked
- **WHEN** the user explicitly declines tracking, or the spec is trivial/disposable
- **THEN** the skill classifies it as "Skip" and takes no OpenSpec action

### Requirement: Backfill workflow for already-completed specs
The skill SHALL provide a workflow that scaffolds OpenSpec change artifacts from an
already-completed `specs/<Name>.spec.md` and immediately archives them, producing a historical
record without leaving the change open.

#### Scenario: Backfilling a completed spec
- **WHEN** a spec is classified as "Backfill now"
- **THEN** the skill maps the spec's sections into `proposal.md`, `specs/<capability>/spec.md`,
  and `design.md`, scaffolds `tasks.md` with every checkbox marked `[x]` to reflect that the work
  is already done, and then invokes the repo's archive workflow so the change is moved into
  `openspec/changes/archive/YYYY-MM-DD-<name>/` and its delta spec is synced into
  `openspec/specs/` in the same operation

#### Scenario: Original spec file preserved
- **WHEN** a backfill completes
- **THEN** the source `specs/<Name>.spec.md` still exists with its original content unchanged,
  except for a one-line pointer noting it is now tracked via the archived OpenSpec change

### Requirement: Immediate-archive handoff matches the real archive contract
The backfill workflow's immediate-archive step SHALL follow the same contract as the repo's
`openspec-archive-change` skill rather than assuming a simplified or bypassed path.

#### Scenario: Delta spec exists at backfill time
- **WHEN** the backfilled change has a delta spec under `specs/<capability>/spec.md`
- **THEN** the archive step syncs that delta into `openspec/specs/<capability-path>/spec.md`
  before moving the change folder, using the same sync-before-move gating the archive skill uses
  for any other change

#### Scenario: Archive folder naming
- **WHEN** the backfilled change is archived
- **THEN** it is moved to `openspec/changes/archive/<YYYY-MM-DD>-<change-name>/`, prefixing today's
  date only if the change name does not already carry a date prefix
