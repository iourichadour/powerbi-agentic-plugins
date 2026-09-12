## Purpose

Defines the `powerbi-architect` agent's requirement to plan a progressive certification task chain for every new or modified measure in specs it authors, so measure test coverage is planned up front without requiring business certification to block initial developer-owned coverage.

## ADDED Requirements

### Requirement: Progressive Test Task Planning Per Measure
For every new or modified measure in a spec authored after this capability takes effect, the `powerbi-architect` agent SHALL plan a `sync` task (agent-automated: generate and self-approve the measure's `Structural` row and append a `Status=Pending` `Certification` placeholder row), a developer-certification task (developer-owned: approve an explicit, reproducible baseline and record `ApprovalSource=Developer`), and a `generate`+`run` task (agent-automated, gated on executable rows). The architect SHALL plan business certification as an optional additive task that records `ApprovalSource=Business`, never as a prerequisite for the developer-certification or `generate`+`run` tasks. Calculated columns and pure formatting/layout tasks are exempt from this requirement.

#### Scenario: Business value unknown at spec time does not block baseline coverage
- **WHEN** a spec includes a new measure whose business-approved value is not yet known
- **THEN** the spec's Tasks list SHALL include `sync`, developer-certification, and `generate`+`run` tasks, and MAY include a separate future business-certification task that is not blocking

#### Scenario: Business value known at spec time is added as business certification
- **WHEN** a spec includes a new measure whose business-approved value was explicitly stated by the business owner during requirements gathering
- **THEN** the spec's Tasks list SHALL include a business-certification task that records the value with `ApprovalSource=Business`, in addition to rather than instead of the executable developer-certification path

#### Scenario: Calculated columns and layout-only tasks are exempt
- **WHEN** a spec's task is a calculated column or a pure formatting/layout change with no new or modified measure
- **THEN** the spec SHALL NOT include a `sync`, developer-certification, business-certification, or `generate`+`run` task for that item

### Requirement: One-Time Assertion Library Setup Prerequisite
When a spec's first measure task targets a semantic model that does not yet have the PQL.Assert assertion library deployed, the `powerbi-architect` agent SHALL add a single one-time setup task — invoking `pql-tester`'s `setup` mode — to deploy the library and to scaffold `Certification/MeasureCertification.csv` and `TESTING.md` from the `dax-unit-testing` skill's templates before the first `sync` task, rather than checking for installation in every subsequent measure task.

#### Scenario: First measure task in an unequipped model gets a setup task
- **WHEN** a spec's first measure task targets a model without the PQL.Assert library deployed
- **THEN** the spec SHALL include exactly one library-deployment setup task preceding the first `sync` task, and SHALL NOT repeat that check in later measure tasks within the same spec

#### Scenario: Setup task scaffolds the registry and TESTING.md only when absent
- **WHEN** the one-time setup task runs against a project that already has a `Certification/MeasureCertification.csv` or a `TESTING.md`
- **THEN** the setup task SHALL leave the existing file(s) unmodified and SHALL only create whichever of the two is missing

### Requirement: Applies Going Forward Only
This test-task-planning requirement SHALL apply only to specs authored after the capability takes effect, and SHALL NOT require retrofitting test tasks into specs already drafted or approved beforehand.

#### Scenario: Pre-existing spec is not retrofitted
- **WHEN** a spec was drafted or approved before this capability took effect
- **THEN** the `powerbi-architect` agent SHALL NOT be required to add sync/developer-certification/generate+run tasks retroactively to that spec
