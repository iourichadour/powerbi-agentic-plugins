## Purpose

Defines the dedicated `pql-tester` agent's explicit operating modes and guardrails so it can establish developer-certified baseline coverage and add business certification later, without fabricating a business-approved value or silencing a failing test.

## Requirements

### Requirement: Explicit Operating Modes
The agent SHALL expose separately-invoked operating modes — `setup`, `scan`, `sync`, `generate`, `run`, `report`, `diagnose` — and SHALL NOT perform `setup`, `sync`, or `generate` as a silent side effect of `scan`, `run`, or `report`.

#### Scenario: Report mode does not trigger sync or generate
- **WHEN** the agent is invoked in `report` mode
- **THEN** it SHALL only read and emit results and coverage statistics, and SHALL NOT modify the registry or generate any `.dax` file

#### Scenario: Scan mode makes no writes
- **WHEN** the agent is invoked in `scan` mode
- **THEN** it SHALL only produce a read-only metadata compliance report and SHALL NOT write to the registry, the model, or the file system

### Requirement: One-Time Project Setup Mode

The agent SHALL provide a `setup` mode that deploys the selected PQL.Assert assertion functions into
the target semantic model and scaffolds `Certification/MeasureCertification.csv` and `TESTING.md` in
the semantic model project from the `dax-unit-testing` skill's templates. `setup` SHALL be idempotent:
it SHALL create each of `Certification/MeasureCertification.csv` and `TESTING.md` only if the file does
not already exist, and SHALL NEVER overwrite either file once present.

#### Scenario: Setup scaffolds both files on an unequipped project
- **WHEN** `setup` runs against a semantic model project with no `Certification/MeasureCertification.csv` and no `TESTING.md`
- **THEN** the agent SHALL create both files from the skill's templates and deploy the PQL.Assert functions

#### Scenario: Setup never overwrites existing project files
- **WHEN** `setup` runs against a project where `Certification/MeasureCertification.csv` or `TESTING.md` already exists
- **THEN** the agent SHALL leave the existing file(s) unmodified and SHALL report that they already existed

### Requirement: Progressive Certification Guardrails
The agent SHALL NOT invent, estimate, or guess an `ExpectedValue`, `Owner`, `FilterExpression`, or `RequirementId` for a `Certification`, `Aggregation`, or `Regression` registry row. The agent MAY self-approve `Structural` rows with `ApprovalSource=Structural`. The agent MAY record a developer-certified, reproducible baseline with `ApprovalSource=Developer` only when a developer explicitly supplies or approves the value in the same request, and MAY record `ApprovalSource=Business` only when a business owner explicitly supplies or approves the value in the same request.

#### Scenario: Agent refuses to guess a baseline or business value
- **WHEN** the agent is asked to certify a `Certification` row and no developer or business owner has supplied or approved `ExpectedValue`
- **THEN** the agent SHALL leave the row at `Status=Pending` rather than inventing a value

#### Scenario: Agent records an explicitly approved developer baseline
- **WHEN** a developer explicitly approves an observed, reproducible `ExpectedValue` and `FilterExpression` for a `Certification` row in the same request
- **THEN** the agent SHALL write those values into the row with `Status=Approved`, `ApprovalSource=Developer`, `ApprovedBy`, and `ApprovedOn`

#### Scenario: Agent records an explicitly stated business value
- **WHEN** a business owner explicitly states the `ExpectedValue`, `FilterExpression`, and `Owner` for a `Certification` row in the same request
- **THEN** the agent SHALL write those values into the row with `Status=Approved` and `ApprovalSource=Business`

#### Scenario: Agent self-approves Structural rows without human input
- **WHEN** the agent generates a `Structural` row for a measure with no existing structural test
- **THEN** the agent SHALL set `Status=Approved` and `ApprovalSource=Structural` on that row without requiring human confirmation

### Requirement: Dual Test Execution Environments
The agent SHALL support executing generated tests against a `DEV` profile (local Power BI Desktop connection) and a `CLOUD` profile (XMLA endpoint), and both profiles SHALL produce identical result artifacts for identical test input. `CLOUD` credentials SHALL be read only from environment variables and SHALL NEVER be embedded, printed, or logged by the agent.

#### Scenario: DEV and CLOUD runs produce identical artifacts
- **WHEN** the same generated `.dax` test file is executed once against `DEV` and once against `CLOUD` with identical data
- **THEN** the two runs SHALL produce result artifacts with the same structure and content

#### Scenario: Cloud credentials are never logged
- **WHEN** the agent executes a `CLOUD` profile run
- **THEN** it SHALL read `PBI_WORKSPACE`, `PBI_MODEL`, `PBI_CLIENT_ID`, `PBI_TENANT_ID`, and `PBI_CLIENT_SECRET` from environment variables only, and SHALL NOT print or write them to any output artifact

### Requirement: Restricted Write Scope
The agent SHALL only write within the `Certification/`, `DAXQueries/`, and `reports/` directories, `TESTING.md`, and the model's assertion-library definition file (e.g. `definition/functions.tmdl`, written only to deploy or update PQL.Assert UDFs during `setup`), and SHALL NEVER modify any other semantic model object (measures, tables, relationships, or model logic).

#### Scenario: Setup may write the assertion-library definition file
- **WHEN** the agent runs `setup` and the PQL.Assert functions are not yet deployed
- **THEN** the agent MAY write the selected PQL.Assert UDFs into the model's assertion-library definition file, and SHALL NOT modify any other model object in the same operation

#### Scenario: Agent refuses to modify a production measure
- **WHEN** the agent detects a failing test caused by a measure's DAX expression
- **THEN** it SHALL report the failure via `diagnose` rather than editing the measure's expression

### Requirement: No Silent Failure Suppression
The agent SHALL NEVER widen a test's `Tolerance` to make a failing test pass, SHALL NEVER set `Status=Retired` for the purpose of silencing a failure, and SHALL NEVER delete or disable a failing test.

#### Scenario: Widening tolerance to pass a test is rejected
- **WHEN** a generated test fails due to a value outside its configured `Tolerance`
- **THEN** the agent SHALL NOT increase that row's `Tolerance` value as a way to make the test pass

#### Scenario: Retiring a row to hide a failure is rejected
- **WHEN** a registry row's test is currently failing
- **THEN** the agent SHALL NOT set that row's `Status` to `Retired` as a means of removing it from execution

### Requirement: Test Naming and Structure Conventions
Generated or authored tests SHALL be created only in the semantic model project's root `DAXQueries/` folder, SHALL be registered in `daxQueries.json`, SHALL follow the `[Area].[Environment].Test(s)` naming convention, and SHALL combine multiple assertions using `UNION`.

#### Scenario: Generated test file follows naming convention
- **WHEN** the agent generates a test file for a measure in the `ANY` environment
- **THEN** the resulting file SHALL be named following the `[Area].[Environment].Test(s)` pattern and registered in `daxQueries.json`
