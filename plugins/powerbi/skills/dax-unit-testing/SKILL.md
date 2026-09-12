---
name: dax-unit-testing
description: |
  DAX Query View unit-testing skill for Power BI semantic models — the PQL.Assert assertion library,
  a CSV-based measure certification registry (schema, TestCategory taxonomy, progressive
  Structural/Developer/Business approval lifecycle), and deterministic validate/generate/certify/
  coverage automation scripts.
  Use when the user asks to unit-test DAX measures, certify a measure's expected value, generate DAX
  Query View tests from a registry, migrate a legacy test registry, report model-wide test coverage,
  or set up/scaffold measure testing (PQL.Assert + starter registry + TESTING.md) on a new project.
  Does NOT execute tests (see `dax-test-framework`) and does NOT validate row-level data quality (see
  `dax-data-quality`/`sql-data-quality`, which test the data, not the model).
metadata:
  version: 0.1.0
---

# DAX Unit Testing — Measure Certification Skill

This skill establishes and maintains a Power BI semantic model's **measure certification
registry**: which measures have DAX Query View tests, what kind of test each is, and who or what
approved the expected value. It does not execute tests — see
[`dax-test-framework`](../dax-test-framework/SKILL.md) for DEV/CLOUD execution, CI reports, and the
HTML dashboard — and it does not validate row-level data (see `dax-data-quality`/`sql-data-quality`:
those test the **data**; this skill tests the **model**).

For the agent that orchestrates this skill end-to-end (`setup`/`scan`/`sync`/`generate`/`run`/
`report`/`diagnose`), see
[`plugins/powerbi/agents/pql-tester.agent.md`](../../agents/pql-tester.agent.md).

## Prerequisites

- **`uv`** is provisioned automatically by `setup-team-plugins.ps1` — no admin rights required.
  This skill's scripts resolve from their own [`pyproject.toml`](pyproject.toml) via
  `uv run --project plugins/powerbi/skills/dax-unit-testing <script>.py ...` (or run from inside
  this skill's directory and omit `--project`).

## Getting Started: One-Time Project Setup

Run once per target semantic model project (idempotent — safe to re-run; never overwrites an
existing file):

```powershell
uv run --project plugins/powerbi/skills/dax-unit-testing \
  plugins/powerbi/skills/dax-unit-testing/assets/scripts/setup_project.py \
  --project-dir "<path to YourModel.SemanticModel>"
```

This:

1. Deploys the PQL.Assert assertion functions ([`references/functions.tmdl`](references/functions.tmdl))
   into `<project>/definition/functions.tmdl` (only if that file does not already exist).
2. Copies [`assets/templates/MeasureCertification.template.csv`](assets/templates/MeasureCertification.template.csv)
   to `<project>/Certification/MeasureCertification.csv` (only if absent).
3. Copies [`assets/templates/TESTING.template.md`](assets/templates/TESTING.template.md) to
   `<project>/TESTING.md` (only if absent).

The `pql-tester` agent's `setup` mode calls this same script — use either directly.

## Table of Contents

| Topic | Reference | When to load |
|---|---|---|
| Registry schema (all 14 columns, `TestCategory`, `Status`, `ApprovalSource`) | [certification-registry-schema.md](references/certification-registry-schema.md) | Before reading or writing any registry row |
| Legacy 11-column migration | [legacy-registry-migration.md](references/legacy-registry-migration.md) | When a project already has an 11-column registry |
| Reserved DAX words | [reserved-dax-words.md](references/reserved-dax-words.md) | When naming new DAX UDFs |
| Model-independent DAX UDFs | [model-independence.md](references/model-independence.md) | When extending `functions.tmdl` with new assertion functions |
| Third-party license notices | [LICENSE-THIRD-PARTY.md](LICENSE-THIRD-PARTY.md) | Attribution for the vendored PQL.Assert assets |

## DAX Query View Test Creation

Tests are DAX Query View `.dax` files in the semantic model project's root `DAXQueries/` folder,
registered in `daxQueries.json`, following `[Area].[Environment].Test(s)` naming (e.g.
`Sales Measures.ANY.Tests.dax`), combining multiple `PQL.Assert.*` calls with `UNION(...)`. Most
tests are produced by `generate_measure_tests.py` from `Status=Approved` registry rows (see
[Progressive Certification Workflow](#progressive-certification-workflow)) — hand-author only for
cases the registry doesn't model (e.g. one-off relationship/perspective/OLS checks).

## Environment Governance

The registry itself has no environment column — environment governance lives in the **generated
test filename**, using the same `ANY`/`DEV`/`PROD` tokens that `dax-test-framework`'s `--environment`
filter recognizes:

- `ANY` — safe to run against both Desktop and a deployed model (the default for generated
  certification suites).
- `DEV` — depends on something only present locally (a dev-only table, a WIP measure).
- `PROD` — depends on something only present in the deployed model.

## Assertion Taxonomy

`references/functions.tmdl` stages PQL.Assert functions across several namespaces — use only the
subset a target model's tests need:

- **Basic / Equality** — `ShouldBeTrue`, `ShouldBeFalse`, `ShouldEqual`, `ShouldNotEqual`,
  `ShouldEqualExactly`.
- **Null / Blank** — `ShouldBeNull`, `ShouldNotBeNull`, `ShouldBeBlank`, `ShouldNotBeBlank`,
  `ShouldBeNullOrBlank`, `ShouldNotBeNullOrBlank` (used for `Structural` rows and `NOT_BLANK`
  `ExpectedValue`s).
- **Numeric** — `ShouldBeGreaterThan`, `ShouldBeLessThan`, `ShouldBeGreaterOrEqual`,
  `ShouldBeLessOrEqual`, `ShouldBeBetween` (used for `Tolerance > 0` and `>=0`/`>0` sentinels).
- **String** — `ShouldStartWith`, `ShouldEndWith`, `ShouldContainString`, `ShouldMatch`.
- **Relationship / Partition / Perspective / OLS / Best Practice** — structural, agent-verifiable
  model checks that don't need developer or business certification; see
  [model-independence.md](references/model-independence.md) before writing new functions in these
  namespaces (avoid assuming schema on `TABLE` parameters).

## Progressive Certification Workflow

See [certification-registry-schema.md](references/certification-registry-schema.md) for the full
column contract. In short:

1. **`sync`** (`assets/scripts/certify_measures.py sync`) — auto-generates and self-approves a
   `Structural` row for every measure missing one (`ApprovalSource=Structural`,
   `ApprovedBy`/`ApprovedOn`=`N/A`), and appends a `Status=Pending` placeholder `Certification` row
   for every measure missing a business-facing test. Never guesses a business value. Flags — never
   deletes — rows whose measure no longer exists.
2. **Developer certification** (`assets/scripts/certify_measures.py certify --approval-source
   Developer`) — a developer explicitly records an observed, reproducible baseline. Makes the row
   immediately generatable/executable without waiting on business sign-off.
3. **`generate`** (`assets/scripts/generate_measure_tests.py`) — turns every `Status=Approved` row
   into a `.dax` file, idempotently, with a content-hash guard against hand-edits
   (`GENERATED_FILE_MODIFIED`).
4. **`run`** — see [`dax-test-framework`](../dax-test-framework/SKILL.md).
5. **Business certification (optional, additive)** — `certify_measures.py certify
   --approval-source Business` when a business owner supplies or approves a value. Never replaces
   or blocks step 2's baseline; a measure may carry both.

## Test Coverage Statistics

`assets/scripts/coverage_report.py` is strictly read-only — never writes to the registry or model
— and reports, per model: % measures with any registry row (vs. untested), % with an executable
`Structural` row, % with a developer-certified row, % with a business-certified row, and a full
`TestCategory` × `Status` × `ApprovalSource` breakdown, as `reports/coverage.json` +
`reports/coverage-summary.md`. This is a snapshot of the registry, not proof tests currently pass —
check `pql-tester report` / `dax-test-framework`'s JUnit output for pass/fail status.

## Legacy Registry Migration

If a project already has an 11-column registry (no `ApprovalSource`/`ApprovedBy`/`ApprovedOn`), use
`assets/scripts/certify_measures.py migrate-legacy` — see
[legacy-registry-migration.md](references/legacy-registry-migration.md). `Structural`/`Approved`
rows map automatically; any other `Approved` row requires an explicit mapping or migration stops
with a clear per-row error — it never guesses `Developer` vs. `Business` provenance.

## Fixed Error Vocabulary

Every script in this skill reports failures using the same fixed, machine-readable vocabulary
consumed by `dax-test-framework`: `VALUE_MISMATCH`, `BLANK_RESULT`, `DAX_ERROR`,
`MEASURE_NOT_FOUND`, `CERTIFICATION_PENDING`, `METADATA_INCOMPLETE`, `REGISTRY_INVALID`,
`GENERATED_FILE_MODIFIED`, `CONNECTION_ERROR` — see
[certification-registry-schema.md](references/certification-registry-schema.md#error-type-vocabulary)
for what each means and which script(s) raise it.

## Scripts Reference

| Script | Purpose | Writes |
|---|---|---|
| [`assets/scripts/setup_project.py`](assets/scripts/setup_project.py) | One-time idempotent scaffolding | `definition/functions.tmdl`, `Certification/MeasureCertification.csv`, `TESTING.md` (only if absent) |
| [`assets/scripts/validate_registry.py`](assets/scripts/validate_registry.py) | Registry integrity checks (`--schema-only` supported) | none (read-only) |
| [`assets/scripts/certify_measures.py`](assets/scripts/certify_measures.py) | `scan` / `sync` / `certify` / `migrate-legacy` | registry only (`sync`/`certify`/`migrate-legacy`); `scan` is read-only |
| [`assets/scripts/generate_measure_tests.py`](assets/scripts/generate_measure_tests.py) | `.dax` generation + `daxQueries.json` registration | `DAXQueries/*.dax`, `daxQueries.json` |
| [`assets/scripts/coverage_report.py`](assets/scripts/coverage_report.py) | Model-wide coverage statistics | `reports/coverage.json`, `reports/coverage-summary.md` (read-only otherwise) |
