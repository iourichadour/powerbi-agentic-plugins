# Testing This Semantic Model

This project uses [PQL.Assert](https://github.com/clientfirsttech/PQL.Assert) DAX Query View unit
tests plus a CSV-based measure certification registry to track test coverage and approval
provenance. This file was scaffolded once by `pql-tester setup` (or the `dax-unit-testing`
skill's `setup_project.py` script) and is safe to edit — it will never be overwritten by later
`setup` runs.

## What is deployed

- **Assertion library**: `definition/functions.tmdl` contains the PQL.Assert `PQL.Assert.*` DAX
  user-defined functions used by every generated and hand-authored test.
- **Registry**: `Certification/MeasureCertification.csv` — one row per measure test. See
  [certification-registry-schema.md](../../plugins/powerbi/skills/dax-unit-testing/references/certification-registry-schema.md)
  in the `dax-unit-testing` skill for the full column contract, or ask the `pql-tester` agent.
- **Tests**: `DAXQueries/*.Tests.dax` (or `*.Test.dax`) — DAX Query View files, registered in
  `daxQueries.json`.

## Naming convention

Test files and DAX Query View tabs follow `[Area].[Environment].Test(s)`, for example:

- `Sales Measures.ANY.Tests.dax` — runs in any environment.
- `Sales Measures.DEV.Tests.dax` — DEV-only (e.g. depends on a dev-only table).
- `MeasureCertification.ANY.Business.Tests.dax` — a generated certification suite.

`ANY` means the suite is safe to run against both a local Power BI Desktop copy and a deployed
Fabric semantic model. Use `DEV` or `PROD` only when a test is genuinely environment-specific.

## The progressive certification workflow

1. **`sync`** — ask `pql-tester` to run `sync`. It auto-generates and self-approves a `Structural`
   row for every measure that doesn't have one, and appends a `Status=Pending` placeholder
   `Certification` row for every measure without a certification test. This never requires
   business input.
2. **Developer certification** — for a measure whose business-approved value isn't known yet, a
   developer can explicitly approve an observed, reproducible value (e.g. "I ran this measure with
   this filter today and got 42,000; that's correct given current data"). Tell `pql-tester` the
   value and filter and ask it to certify the row — it will record
   `Status=Approved`, `ApprovalSource=Developer`, `ApprovedBy`, `ApprovedOn`. This makes the test
   generatable and runnable immediately.
3. **`generate` + `run`** — ask `pql-tester` to generate `.dax` files from every `Approved` row and
   run them against `DEV` (local Desktop) or `CLOUD` (deployed Fabric model).
4. **Business certification (optional, additive)** — when a business owner supplies or approves an
   expected value, ask `pql-tester` to record it with `ApprovalSource=Business`. This never
   replaces or blocks the developer-certified baseline; a measure can have both.

`pql-tester` will never invent an `ExpectedValue`, `Owner`, `FilterExpression`, or `RequirementId`
for you — if you ask it to certify a row without supplying or approving a value, it leaves the row
`Pending`.

## Running tests locally (Power BI Desktop)

```powershell
uv run dax-test-framework/scripts/run_dax_tests.py --profile DEV --model-dir "<path to this project>"
```

The runner auto-discovers the newest Power BI Desktop instance's tabular engine port — no
configuration needed as long as this project is open in Desktop.

## Running tests via the Python framework (CLOUD / CI)

```powershell
$env:PBI_WORKSPACE = "<workspace name or id>"
$env:PBI_MODEL = "<semantic model name>"
$env:PBI_CLIENT_ID = "<service principal client id>"
$env:PBI_TENANT_ID = "<tenant id>"
$env:PBI_CLIENT_SECRET = "<service principal secret>"   # from a secret store, never hard-coded
uv run dax-test-framework/scripts/run_dax_tests.py --profile CLOUD --model-dir "<path to this project>"
```

Or via pytest:

```powershell
uv run pytest dax-test-framework/scripts/test_dax_suite.py --profile CLOUD
```

Reports are written to `reports/` as JUnit XML and Markdown. Open
`dax-test-framework/assets/dax-test-dashboard.html` (served over a local HTTP server, e.g.
`python -m http.server`) to review results visually.

## The measure-certification handoff

When you add or change a measure:

1. Run `sync` (adds/updates its `Structural` row and a `Pending` `Certification` placeholder).
2. Certify a developer baseline so the measure has immediate, executable coverage.
3. Generate and run the suite.
4. If/when a business owner is available, ask them for the expected value under a specific filter
   and record it as an additional `Business`-certified row — this is optional and never blocks the
   steps above.

See `pql-tester`'s `report` mode for current pass/fail status and `coverage_report.py`'s output
(`reports/coverage.json`, `reports/coverage-summary.md`) for model-wide test coverage statistics.
