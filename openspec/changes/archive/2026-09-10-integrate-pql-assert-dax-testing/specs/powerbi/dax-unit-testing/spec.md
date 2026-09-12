## Purpose

Provides a DAX Query View unit-testing skill for Power BI semantic models: a CSV-based measure certification registry contract, deterministic validation/generation/reporting automation, and a coverage-statistics workflow that let agents and developers test and certify measures without fabricating business-approved values.

## ADDED Requirements

### Requirement: Measure Certification Registry Schema
Every target semantic model project's `Certification/MeasureCertification.csv` SHALL use the exact column schema, in order: `MeasureName, TestName, TestCategory, FilterExpression, ExpectedValue, Tolerance, Owner, Status, ApprovalSource, ApprovedBy, ApprovedOn, Severity, RequirementId, LastReviewed`.

#### Scenario: Registry header matches schema
- **WHEN** a `Certification/MeasureCertification.csv` file is read by any registry-aware tool
- **THEN** the tool SHALL treat a header that does not match the schema exactly (name, order, or count of columns) as invalid input

### Requirement: TestCategory Classification
Each registry row SHALL declare a `TestCategory` of exactly one of `Structural` (integrity only, no business value), `Certification` (business-approved value plus non-empty `FilterExpression`), `Aggregation` (parts sum to whole), or `Regression` (a previously certified period stays unchanged).

#### Scenario: Structural row requires no business value
- **WHEN** a row's `TestCategory` is `Structural`
- **THEN** the row is permitted to have an empty `FilterExpression` and does not require a business-supplied `ExpectedValue`

#### Scenario: Non-Structural row requires a filter expression
- **WHEN** a row's `TestCategory` is `Certification`, `Aggregation`, or `Regression`
- **THEN** the row SHALL have a non-empty `FilterExpression` that is valid DAX droppable directly into `CALCULATE`

#### Scenario: ApprovalSource=Structural is reserved for Structural rows
- **WHEN** a row declares `ApprovalSource=Structural`
- **THEN** its `TestCategory` SHALL also be `Structural`, and a `Structural` row SHALL NOT declare `ApprovalSource=Developer` or `ApprovalSource=Business`

### Requirement: Status Lifecycle
Each registry row's `Status` SHALL be one of `Pending` (placeholder, not eligible for generation), `Approved` (eligible for test generation and execution), or `Retired` (excluded from generation and execution, retained for audit). An `Approved` row SHALL declare an `ApprovalSource` of `Structural`, `Developer`, or `Business`; `ApprovedBy` and `ApprovedOn` SHALL identify the approving person and ISO date for `Developer` and `Business` rows, and SHALL both carry the literal sentinel `N/A` for `ApprovalSource=Structural` rows.

#### Scenario: Structural approval carries the not-applicable sentinel
- **WHEN** a row is auto-approved with `ApprovalSource=Structural`
- **THEN** its `ApprovedBy` and `ApprovedOn` SHALL be written as `N/A` rather than left empty or filled with an agent identity or date

#### Scenario: Pending row is excluded from generation
- **WHEN** a row's `Status` is `Pending`
- **THEN** test generation SHALL skip the row and report it under the `CERTIFICATION_PENDING` error type

#### Scenario: Developer-certified row is eligible for generation
- **WHEN** a row has `Status=Approved` and `ApprovalSource=Developer`
- **THEN** test generation SHALL include the row without requiring a separate business approval

#### Scenario: Retired row is excluded but retained
- **WHEN** a row's `Status` is `Retired`
- **THEN** test generation and execution SHALL skip the row without deleting it from the registry

### Requirement: Registry Validation
A registry validation tool SHALL enforce every integrity rule from the schema contract — header match, `MeasureName`+`TestName` uniqueness, `MeasureName` existing in the model, permitted `TestCategory`/`Status`/`ApprovalSource`/`Severity` values, the `ApprovalSource=Structural` ⇔ `TestCategory=Structural` pairing, non-empty `FilterExpression` unless `Structural`, `ExpectedValue` numeric or one of `NOT_BLANK`/`>=0`/`>0` when `Approved` (never `TBD`), `Tolerance` numeric and `>= 0`, and valid ISO `ApprovedOn`/`LastReviewed` dates (or the `N/A` sentinel where the schema permits it) — and SHALL report any violation distinctly as error type `REGISTRY_INVALID` rather than a generic failure.

The tool SHALL additionally offer a schema-only mode that applies every rule not requiring a live semantic model, so a registry or template can be validated in CI without a model connection.

#### Scenario: Schema-only validation runs without a model
- **WHEN** validation is invoked in schema-only mode against a registry file with no model available
- **THEN** it SHALL apply all structural, vocabulary, uniqueness, and value rules, SHALL skip only the `MeasureName`-exists-in-model rule, and SHALL report that the model-existence rule was not evaluated

#### Scenario: Approved row left at placeholder value fails validation
- **WHEN** a registry row has `Status=Approved` and `ExpectedValue=TBD`
- **THEN** validation SHALL fail that row with error type `REGISTRY_INVALID`

#### Scenario: Duplicate MeasureName and TestName pair fails validation
- **WHEN** two rows share the same `MeasureName` and `TestName`
- **THEN** validation SHALL fail with error type `REGISTRY_INVALID`

### Requirement: Deterministic Test Generation
Generating `.dax` test files from `Status=Approved` registry rows SHALL be idempotent — identical registry input SHALL produce byte-identical output — and SHALL never silently overwrite a file whose content no longer matches the last generated hash. Generation SHALL also register every generated file in the project's `daxQueries.json` deterministically, preserving existing unrelated entries.

#### Scenario: Repeated generation from unchanged input is byte-identical
- **WHEN** test generation runs twice against the same `Approved` registry rows with no other changes
- **THEN** the two generated `.dax` outputs SHALL be byte-identical

#### Scenario: Generated files are registered without disturbing existing entries
- **WHEN** generation writes or refreshes a `.dax` test file in a project whose `daxQueries.json` already lists hand-authored queries
- **THEN** the generated file SHALL be present in `daxQueries.json` exactly once, the pre-existing entries SHALL be preserved, and a second identical run SHALL leave `daxQueries.json` byte-identical

#### Scenario: Hand-edited generated file blocks regeneration
- **WHEN** a previously generated `.dax` file has been modified by hand and generation runs again for the same measure
- **THEN** generation SHALL fail that file with error type `GENERATED_FILE_MODIFIED` instead of overwriting it

### Requirement: Model Scan and Sync
Scanning a semantic model SHALL produce a read-only metadata compliance report (description, format string, display folder, home table, registry coverage) without modifying the registry or model. Syncing the registry against the model SHALL auto-generate and auto-approve `Structural` rows for measures lacking them, append a `Status=Pending` placeholder `Certification` row for measures lacking one, and flag — never auto-delete — registry rows whose measure no longer exists in the model. A developer SHALL be able to certify an existing non-Structural row from an explicit, reproducible baseline by setting its `ApprovalSource=Developer`, recording the developer and approval date, and setting `Status=Approved`.

#### Scenario: New measure gets an auto-approved Structural row on sync
- **WHEN** sync runs against a measure with no existing registry rows
- **THEN** sync SHALL add a `Structural` row with `Status=Approved` and `ApprovalSource=Structural` for that measure without requiring human input

#### Scenario: New measure gets a pending certification placeholder on sync
- **WHEN** sync runs against a measure with no existing `Certification`/`Aggregation`/`Regression` row
- **THEN** sync SHALL append a row with `Status=Pending`, `ExpectedValue=TBD`, and `Owner=TBD` for that measure

#### Scenario: Orphaned row is flagged, not deleted
- **WHEN** sync finds a registry row whose `MeasureName` no longer exists in the model
- **THEN** sync SHALL flag the row as orphaned and SHALL NOT remove it from the registry

#### Scenario: Sync never guesses a business value
- **WHEN** sync processes a `Certification`, `Aggregation`, or `Regression` row and no explicit value was supplied in the same request
- **THEN** sync SHALL leave `FilterExpression`, `ExpectedValue`, `Owner`, and `RequirementId` unset rather than inferring a value

#### Scenario: Sync records an explicitly supplied business value
- **WHEN** a human explicitly supplies `FilterExpression`, `ExpectedValue`, and `Owner` for a `Certification`/`Aggregation`/`Regression` row in the same request
- **THEN** sync SHALL write the supplied values into that row and SHALL be permitted to set `Status=Approved` with `ApprovalSource=Business`

#### Scenario: Developer certifies a reproducible baseline
- **WHEN** a developer explicitly approves a measured, reproducible expected value for a `Certification`, `Aggregation`, or `Regression` row
- **THEN** the tooling SHALL record the value with `Status=Approved`, `ApprovalSource=Developer`, `ApprovedBy`, and `ApprovedOn` and SHALL permit it to be generated and executed before business certification is available

### Requirement: Test Coverage Statistics
A coverage-reporting tool SHALL compute, read-only, the fraction of a semantic model's measures with at least one registry row (vs. measures with zero rows), the fraction with an executable `Structural` row, the fraction with a developer-certified non-Structural row, the fraction with a business-certified non-Structural row, and a breakdown by `TestCategory` × `Status` × `ApprovalSource`, and SHALL emit both a machine-readable and a human-readable coverage artifact without writing to the registry or the model.

#### Scenario: Coverage report identifies untested measures
- **WHEN** coverage reporting runs against a model containing measures with zero registry rows
- **THEN** the emitted report SHALL list each such measure as untested

#### Scenario: Coverage report is read-only
- **WHEN** coverage reporting completes
- **THEN** the registry file and the semantic model SHALL be unmodified

### Requirement: Error Type Vocabulary
Registry and test-execution tooling SHALL classify every failure using one of a fixed, machine-readable set of error types: `VALUE_MISMATCH`, `BLANK_RESULT`, `DAX_ERROR`, `MEASURE_NOT_FOUND`, `CERTIFICATION_PENDING`, `METADATA_INCOMPLETE`, `REGISTRY_INVALID`, `GENERATED_FILE_MODIFIED`, `CONNECTION_ERROR`.

#### Scenario: Unclassifiable failure still uses the fixed vocabulary
- **WHEN** any registry validation, generation, scan/sync, or test-execution operation fails
- **THEN** the failure SHALL be reported using one of the fixed error type values, not a free-form message alone

### Requirement: Legacy Registry Migration

The skill SHALL provide an explicit migration path for target projects using a legacy
11-column registry schema
(`MeasureName, TestName, TestCategory, FilterExpression, ExpectedValue, Tolerance, Owner, Status,
Severity, RequirementId, LastReviewed`) before adopting the extended approval-audit schema. The
migration SHALL preserve all existing values, SHALL require an explicit mapping for approval
provenance fields, and SHALL reject ambiguous approved rows rather than inferring business or
developer approval.

#### Scenario: Structural legacy row can be mapped automatically
- **WHEN** a legacy row is `Status=Approved` and `TestCategory=Structural`
- **THEN** migration MAY set `ApprovalSource=Structural` and SHALL leave business/developer identity fields explicitly marked as not applicable

#### Scenario: Ambiguous approved legacy row is blocked
- **WHEN** a legacy non-Structural row is `Status=Approved` without explicit provenance
- **THEN** migration SHALL stop with a clear migration error and SHALL not label the row as Business or Developer

#### Scenario: Pending and retired legacy rows remain auditable
- **WHEN** a legacy row is `Pending` or `Retired`
- **THEN** migration SHALL preserve its values and status while adding the extended columns without enabling execution

### Requirement: Onboarding Template Assets

The skill SHALL ship a starter `MeasureCertification.template.csv` (the exact 14-column schema header
plus one illustrative row per `TestCategory`/`Status`/`ApprovalSource` combination) and a generalized
`TESTING.template.md` (a project-agnostic testing guide covering
PQL.Assert deployment, naming conventions, running tests locally and via the Python framework, and the
measure-certification handoff). Template rows SHALL use only illustrative, obviously synthetic values;
rows shown as `Approved` SHALL carry a validation-legal `ExpectedValue` (for example `NOT_BLANK`,
`>=0`, or a synthetic numeric) rather than the `TBD` placeholder, which SHALL appear only on `Pending`
rows. Neither template SHALL contain a source-project's model name, measure
names, or live business values.

#### Scenario: Template CSV matches the registry schema
- **WHEN** `MeasureCertification.template.csv` is validated by the registry validation tool in schema-only mode
- **THEN** it SHALL pass header and row-level validation without modification

#### Scenario: Template contains no source-project data
- **WHEN** the two onboarding templates are inspected
- **THEN** they SHALL contain only generic placeholder names and values, with no measure names, business figures, or file paths traceable to any specific target project

### Requirement: Idempotent Project Scaffolding

The skill SHALL provide a deterministic, separately-invocable scaffolding entry point that deploys the
selected PQL.Assert assertion functions into a target semantic model's assertion-library definition
file and copies `MeasureCertification.template.csv` to `Certification/MeasureCertification.csv` and
`TESTING.template.md` to the semantic model project's `TESTING.md`. Scaffolding SHALL create each
destination file only if it does not already exist, SHALL NEVER overwrite an existing file, SHALL
report which destinations already existed, and SHALL NOT write to any semantic model object other than
the assertion-library definition file.

#### Scenario: Second scaffolding run makes no changes
- **WHEN** scaffolding runs against a project that has already been scaffolded
- **THEN** it SHALL leave every destination file byte-identical and SHALL report each destination as already present

#### Scenario: Partially scaffolded project is completed, not overwritten
- **WHEN** scaffolding runs against a project that has `Certification/MeasureCertification.csv` but no `TESTING.md`
- **THEN** it SHALL create only `TESTING.md` and SHALL leave the existing registry unmodified
