# Measure Certification Registry Schema

`Certification/MeasureCertification.csv` is the single source of truth for which measures have
tests, what category those tests are, and who approved the expected value. Every registry-aware
script (`validate_registry.py`, `generate_measure_tests.py`, `certify_measures.py`,
`coverage_report.py`, `setup_project.py`) reads and writes this exact schema.

This document is the **contract**. Read it before writing a row by hand, before extending any
script, and before migrating a legacy registry (see
[legacy-registry-migration.md](legacy-registry-migration.md)).

## Column Schema (exact order)

```
MeasureName, TestName, TestCategory, FilterExpression, ExpectedValue, Tolerance, Owner, Status, ApprovalSource, ApprovedBy, ApprovedOn, Severity, RequirementId, LastReviewed
```

A header that does not match this list exactly — same names, same order, same count — is invalid
input. Tools SHALL reject it rather than guess a mapping.

| Column | Type | Required | Notes |
|---|---|---|---|
| `MeasureName` | string | always | Must exist in the model, except under `--schema-only` validation (see below). |
| `TestName` | string | always | Unique per `MeasureName` — the pair `(MeasureName, TestName)` must be unique across the registry. |
| `TestCategory` | enum | always | `Structural`, `Certification`, `Aggregation`, or `Regression`. See [TestCategory Definitions](#testcategory-definitions). |
| `FilterExpression` | DAX fragment | conditional | Non-empty and valid DAX droppable directly into `CALCULATE(...)` for `Certification`/`Aggregation`/`Regression`. May be empty for `Structural`. |
| `ExpectedValue` | string/numeric | conditional | Required (non-`TBD`) when `Status=Approved`. Valid forms: a numeric literal, `NOT_BLANK`, `>=0`, or `>0`. `TBD` is only valid on `Status=Pending` rows. |
| `Tolerance` | numeric | conditional | Required for numeric `ExpectedValue` comparisons; must be `>= 0`. |
| `Owner` | string | conditional | The business or developer owner of the expected value. `TBD` only on `Pending` rows. |
| `Status` | enum | always | `Pending`, `Approved`, or `Retired`. See [Status Lifecycle](#status-lifecycle). |
| `ApprovalSource` | enum | conditional | `Structural`, `Developer`, or `Business`. Required when `Status=Approved`. See [ApprovalSource Audit Trail](#approvalsource-audit-trail). |
| `ApprovedBy` | string | conditional | The approving person's identity for `Developer`/`Business` approvals; literal `N/A` for `Structural`. |
| `ApprovedOn` | ISO date | conditional | `YYYY-MM-DD` for `Developer`/`Business` approvals; literal `N/A` for `Structural`. |
| `Severity` | enum | always | `Blocker`, `Critical`, `Major`, `Minor`, or `Info` (consuming CI decides which severities gate a merge — out of scope for this repo). |
| `RequirementId` | string | optional | Free-text traceability link (e.g. a spec requirement ID or ticket key). `TBD` only on `Pending` rows. |
| `LastReviewed` | ISO date | always | `YYYY-MM-DD` of the last time a human or script reviewed this row. |

## TestCategory Definitions

- **`Structural`** — integrity only, no business value. Verifies the measure exists, has required
  metadata, and returns without a DAX error. Never needs a `FilterExpression` or business-supplied
  `ExpectedValue`. Fully automated end-to-end (agent-generated, agent-approved).
- **`Certification`** — a business-approved value under a specific, named filter context. Requires
  a non-empty `FilterExpression` and an `ExpectedValue` that is either developer-certified or
  business-certified.
- **`Aggregation`** — verifies that parts sum to the whole (e.g. a set of category totals equals a
  grand total). Requires a non-empty `FilterExpression`.
- **`Regression`** — verifies that a previously certified value for a fixed historical period has
  not silently changed (e.g. a monthly close that should never recalculate). Requires a non-empty
  `FilterExpression`.

`Certification`, `Aggregation`, and `Regression` are collectively "non-Structural" rows throughout
this schema and the scripts that consume it.

## Status Lifecycle

- **`Pending`** — a placeholder row. Not eligible for generation or execution. `ExpectedValue` and
  `Owner` are `TBD` until a developer or business owner supplies a value.
- **`Approved`** — eligible for `.dax` generation and execution. Requires `ApprovalSource`, and
  (except for `Structural`) requires `ApprovedBy` and `ApprovedOn`.
- **`Retired`** — excluded from generation and execution but retained in the file for audit. Never
  delete a row to retire it.

## ApprovalSource Audit Trail

`ApprovalSource` records **who or what** made the row executable — independent of whether the value
is "correct" from a business point of view:

- **`Structural`** — the row was auto-generated and auto-approved by `pql-tester sync`. Reserved
  exclusively for `TestCategory=Structural` rows: a row cannot declare
  `ApprovalSource=Structural` unless `TestCategory=Structural`, and a `Structural` row cannot
  declare `ApprovalSource=Developer` or `ApprovalSource=Business`. `ApprovedBy` and `ApprovedOn`
  SHALL both be the literal sentinel `N/A` — not an empty cell, not an agent identity, not today's
  date — because no human approved anything.
- **`Developer`** — a developer explicitly approved an observed, reproducible baseline value (for
  example, "I ran this measure with this filter and it returned 42,000; that's the correct,
  reproducible value given today's data"). Makes the row executable immediately, without waiting
  for business sign-off. `ApprovedBy` is the developer's identity; `ApprovedOn` is the ISO date of
  approval.
- **`Business`** — a business owner explicitly supplied or approved the expected value. Additive:
  it never replaces or blocks a `Developer`-approved row; a model may carry both a developer
  baseline test and, separately, a business-certified test for the same measure.

`Status=Approved` means *eligible for generation/execution* — it does not by itself mean
business-signed-off. Coverage reporting (see
[Test Coverage Statistics](#test-coverage-statistics-and-scan-vs-coverage)) always breaks Structural,
developer-certified, and business-certified coverage out separately rather than collapsing them
into a single percentage, precisely so this distinction stays visible.

## FilterExpression Rule

`FilterExpression` is a DAX fragment meant to be dropped directly into `CALCULATE(<measure>,
<FilterExpression>)` (or an equivalent construct in the generated `.dax` test). It must:

- Be non-empty for `Certification`, `Aggregation`, and `Regression` rows.
- Be syntactically valid, self-contained DAX (a boolean filter expression, a table expression
  usable as a `CALCULATE` filter argument, or `ALL(...)`/`KEEPFILTERS(...)` wrappers) — not a full
  measure definition or a `DEFINE`/`EVALUATE` block.
- Be empty (or absent) for `Structural` rows, since a structural check does not evaluate the
  measure under any specific filter context.
- Not contain unescaped double quotes that would break CSV field quoting; wrap any value literal
  containing a comma in double quotes per standard CSV quoting rules (see
  [Registry Validation](#registry-validation) for how `validate_registry.py` parses
  quoted-comma fields).

## Registry Validation

`validate_registry.py` enforces, for every row:

1. Header matches the schema exactly (name, order, count).
2. `(MeasureName, TestName)` pairs are unique across the file.
3. `MeasureName` exists in the model (skipped under `--schema-only`; see below).
4. `TestCategory` is one of the four permitted values.
5. `Status` is one of the three permitted values.
6. `ApprovalSource` is one of the three permitted values, and is present whenever `Status=Approved`.
7. `ApprovalSource=Structural` if and only if `TestCategory=Structural`.
8. `FilterExpression` is non-empty unless `TestCategory=Structural`.
9. `ExpectedValue` is a valid form (numeric, `NOT_BLANK`, `>=0`, `>0`) whenever `Status=Approved`;
   `ExpectedValue=TBD` on an `Approved` row is a validation failure.
10. `Tolerance` is numeric and `>= 0` when present.
11. `ApprovedOn` and `LastReviewed` are valid ISO (`YYYY-MM-DD`) dates, except that `ApprovedOn`
    (and `ApprovedBy`) may be the literal sentinel `N/A` only on `ApprovalSource=Structural` rows.
12. `Severity` is one of the permitted values.

Any violation of rules 1–12 is reported as error type `REGISTRY_INVALID` (see the fixed
[error-type vocabulary](#error-type-vocabulary) below) — never a generic/free-form failure message.

### `--schema-only` mode

Rule 3 ("`MeasureName` exists in the model") is the only rule that requires a live model connection
or a parsed TMDL tree. `validate_registry.py --schema-only` applies every other rule and explicitly
reports rule 3 as **not evaluated** (rather than silently passing or silently failing it). This lets
a registry — including the shipped `MeasureCertification.template.csv` — be validated in CI or
before a model connection is available.

## Legacy Registry Migration

See [legacy-registry-migration.md](legacy-registry-migration.md) for the full 11-column legacy
schema, the explicit provenance-mapping rule, and which legacy rows can be auto-mapped versus which
are rejected as ambiguous.

## Test Coverage Statistics (and scan vs. coverage)

`coverage_report.py` is a strictly read-only script, separate from `certify_measures.py scan`. It
computes:

- % of model measures with **any** registry row, vs. untested (zero rows).
- % with an executable `Structural` row.
- % with a developer-certified non-Structural row (`ApprovalSource=Developer`, `Status=Approved`).
- % with a business-certified non-Structural row (`ApprovalSource=Business`, `Status=Approved`).
- A full `TestCategory` × `Status` × `ApprovalSource` breakdown.

It writes `reports/coverage.json` (machine-readable) and `reports/coverage-summary.md`
(human-readable), and never writes to the registry or the model. `certify_measures.py scan` is a
different, narrower report: a per-measure metadata compliance check (description, format string,
display folder, home table, registry coverage) — not a model-wide statistic.

## Error Type Vocabulary

Every registry validation, generation, scan/sync, and test-execution failure across both
`dax-unit-testing` and `dax-test-framework` is classified with exactly one of these fixed,
machine-readable values — never a free-form message alone:

| Error Type | Meaning |
|---|---|
| `VALUE_MISMATCH` | An assertion's actual result did not match its expected value/tolerance. |
| `BLANK_RESULT` | An assertion's `Passed` column was blank or unrecognized. |
| `DAX_ERROR` | A query raised a DAX evaluation error. |
| `MEASURE_NOT_FOUND` | A registry row references a `MeasureName` that does not exist in the model. |
| `CERTIFICATION_PENDING` | Generation skipped a `Status=Pending` row. |
| `METADATA_INCOMPLETE` | A `scan`-reported measure is missing required metadata (description, format string, display folder, home table). |
| `REGISTRY_INVALID` | A registry row or file failed one of the validation rules above. |
| `GENERATED_FILE_MODIFIED` | A previously generated `.dax` file was hand-edited and generation refused to overwrite it. |
| `CONNECTION_ERROR` | The DEV/CLOUD transport could not connect (see `dax-test-framework`). |

## Onboarding Templates

New projects should not hand-author this schema from scratch. See
[Onboarding Template Assets](../assets/templates/) (`MeasureCertification.template.csv`,
`TESTING.template.md`) and `assets/scripts/setup_project.py`, which scaffolds both into a target
project only if the destination files do not already exist.
