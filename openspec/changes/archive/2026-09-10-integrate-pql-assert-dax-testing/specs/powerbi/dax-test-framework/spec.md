## Purpose

Provides a reusable execution framework for PQL.Assert-backed DAX Query View tests so the same
source-controlled `.dax` suites can run against local Power BI Desktop and deployed Fabric
semantic models with deterministic diagnostics and CI-compatible reports.

## ADDED Requirements

### Requirement: Shared DAX Query Execution Contract

The framework SHALL execute the raw text of each discovered `.dax` test file through one shared
ADOMD.NET-backed transport and SHALL return native result rows keyed by clean column names,
preserving DAX `BLANK()` as a null value. It SHALL not serialize result rows through CSV or JSON
as an intermediate parsing format.

#### Scenario: Typed assertion rows are preserved
- **WHEN** a DAX test returns `TestName`, `Expected`, `Actual`, and `Passed` columns containing commas, scientific notation, or `BLANK()`
- **THEN** the framework SHALL preserve the values without delimiter corruption and represent `BLANK()` as null

### Requirement: DEV and CLOUD Profiles

The framework SHALL support a `DEV` profile that discovers the current Power BI Desktop tabular
engine port from the newest UTF-16 `msmdsrv.port.txt` under the user's Power BI Desktop workspace
directory, and a `CLOUD` profile that connects to a Fabric XMLA endpoint using
`PBI_WORKSPACE`, `PBI_MODEL`, `PBI_CLIENT_ID`, `PBI_TENANT_ID`, and `PBI_CLIENT_SECRET` from the
process environment. Credentials SHALL never be printed or written to reports.

#### Scenario: Desktop port is dynamic
- **WHEN** Power BI Desktop is running and multiple workspace port files exist
- **THEN** the DEV profile SHALL select the newest valid port file rather than using a hard-coded port

#### Scenario: Missing cloud configuration is diagnosed
- **WHEN** a CLOUD run is requested and one or more required environment variables are missing
- **THEN** the framework SHALL report only the missing variable names and SHALL not attempt a partial connection

### Requirement: Smoke Gate and Failure Classification

Before executing a suite, the framework SHALL run a PQL.Assert smoke assertion and require one
passing result. A connection failure, missing PQL.Assert library, query execution error, assertion
failure, and indeterminate blank `Passed` value SHALL remain distinct outcomes with non-zero
process status when applicable. Every such failure SHALL be labelled with the shared machine-readable
error type vocabulary defined by the `powerbi/dax-unit-testing` capability (`VALUE_MISMATCH`,
`BLANK_RESULT`, `DAX_ERROR`, `MEASURE_NOT_FOUND`, `CERTIFICATION_PENDING`, `METADATA_INCOMPLETE`,
`REGISTRY_INVALID`, `GENERATED_FILE_MODIFIED`, `CONNECTION_ERROR`) rather than a free-form label.

#### Scenario: Execution failures use the shared error vocabulary
- **WHEN** a run fails to connect, a query raises a DAX error, or an assertion reports a value mismatch
- **THEN** the console output, JUnit XML, and Markdown artifacts SHALL each carry the corresponding fixed error type value (`CONNECTION_ERROR`, `DAX_ERROR`, `VALUE_MISMATCH`)

#### Scenario: Missing assertion library stops the suite
- **WHEN** the transport connects but the smoke assertion cannot execute or does not pass
- **THEN** the framework SHALL stop before reporting the remaining suite as assertion failures and SHALL identify the PQL.Assert prerequisite

#### Scenario: Blank Passed is not a pass
- **WHEN** an assertion row returns a blank or unrecognized `Passed` value
- **THEN** the framework SHALL classify that row as an error rather than silently passing it

### Requirement: Discovery and Targeted Execution

The framework SHALL discover root-level `*Tests.dax` and `*Test.dax` files, exclude known scratch
queries such as `Query 1.dax`, support an optional case-insensitive filename substring filter,
and support independent `ANY`, `DEV`, and `PROD` filename-environment filtering. Empty selections
SHALL be reported as a non-successful run.

#### Scenario: Targeted certification execution
- **WHEN** a caller supplies a filename filter matching `MeasureCertification.ANY.Business`
- **THEN** the framework SHALL run the smoke gate and only matching test files

#### Scenario: No environment match is not success
- **WHEN** an environment filter selects zero test files
- **THEN** the framework SHALL report the available environment tokens and return a non-successful outcome

### Requirement: CLI, Pytest, and Notebook Entry Points

The framework SHALL provide a standalone CLI runner, a pytest wrapper, and DEV/CLOUD notebook
templates that use the same helper and discovery/parser logic. Python tooling SHALL be invoked via
`uv run` in documented commands, and the notebook configuration SHALL make profile, model path,
and filters explicit rather than embedding a model-specific path.

#### Scenario: Both runners use the same suite
- **WHEN** the CLI and pytest wrapper run against the same profile and model directory
- **THEN** both SHALL discover the same `.dax` files and apply the same smoke gate and assertion semantics

### Requirement: CI-Compatible Reports

Successful and failed runs SHALL emit a console summary plus JUnit XML and Markdown failure
artifacts containing test-file, assertion, expected, actual, and status information. The process
SHALL exit with code zero only when every selected assertion passes and no query errors occur.

#### Scenario: Failed assertion produces actionable artifacts
- **WHEN** one selected assertion fails or a query file errors
- **THEN** the run SHALL emit non-zero status and identify the affected file and assertion in both report formats

### Requirement: Runtime XML Dashboard

The framework SHALL provide a repository-agnostic static HTML dashboard that loads JUnit XML
artifacts produced by the runners at runtime instead of embedding test results. The dashboard SHALL
support cache-busted refresh from a configurable relative XML path, parse both `testsuite` and
`testsuites` documents, display aggregate pass/fail/error counts and suite health, support
search/status filtering, and provide a local XML file-picker fallback when automatic fetch is
blocked by browser file-origin rules or no local server is available.

#### Scenario: Dashboard refreshes from a new XML artifact
- **WHEN** a new JUnit XML artifact replaces the configured report file
- **THEN** pressing Refresh results SHALL load the new artifact without changing the HTML file

#### Scenario: Dashboard supports direct file review
- **WHEN** automatic XML fetch fails or a reviewer opens the dashboard from a local file
- **THEN** the dashboard SHALL explain the serving requirement and allow one or more local XML files to be selected for parsing

#### Scenario: Dashboard does not embed generated results
- **WHEN** the HTML asset is inspected without an XML artifact
- **THEN** it SHALL contain viewer logic and configuration only, not generated test-case rows or live result values

### Requirement: Sanitized Sample Artifacts

The framework skill SHALL include representative, repository-agnostic sample artifacts for the
dashboard and evaluation workflow: one CLI-style JUnit XML report, one pytest-style JUnit XML
report, and one Markdown failure summary. Samples SHALL use generic suite/test names and SHALL
contain no credentials, customer data, machine names, or source-repository paths.

#### Scenario: Sample artifacts exercise both XML shapes
- **WHEN** the dashboard is loaded with either sample XML artifact
- **THEN** it SHALL render the same aggregate and per-test status model without special-case code

#### Scenario: Sample artifacts are safe to share
- **WHEN** a repository search scans the sample bundle
- **THEN** it SHALL find no secrets, customer-specific identifiers, or absolute local paths

### Requirement: Generated Certification Suite Reuses the Framework

A generated certification suite SHALL follow the same root-level naming and result contract as
hand-authored DAX suites so the existing discovery, CLI, pytest, notebook, and DAX Query View
paths include it automatically. It SHALL support independent filename targeting without a second
execution harness.

#### Scenario: Generated suite is included in batch execution
- **WHEN** `MeasureCertification.ANY.Business.Tests.dax` exists and no filename filter is supplied
- **THEN** the normal batch runners SHALL discover and report it alongside other test files
