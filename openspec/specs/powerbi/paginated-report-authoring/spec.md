## Purpose

Provide a discoverable, reproducible workflow for authoring and publishing RDL paginated reports over Power BI semantic models from the Power BI plugin.

## Requirements

### Requirement: Paginated report requests route to a dedicated skill

The Power BI plugin SHALL expose a `paginated-report-authoring` skill whose discovery metadata matches requests to create, generate, parameterize, validate, publish, upload, or troubleshoot RDL paginated reports. Interactive PBIR/PBIP report requests SHALL remain routable to the existing interactive report-authoring skill.

#### Scenario: User asks to create an RDL report
- **WHEN** a user asks to create a paginated report, RDL report, or report-builder RDL
- **THEN** the Power BI agent selects the paginated-report-authoring skill and provides its workflow

#### Scenario: User asks to edit an interactive report
- **WHEN** a user asks to edit PBIR/PBIP pages, visuals, themes, or bookmarks
- **THEN** the Power BI agent continues to select the existing powerbi-report-authoring skill

### Requirement: Authoring workflow discovers and binds the semantic model

The skill SHALL require discovery of the target workspace and semantic model name and GUID before generating an RDL. The generated report SHALL bind to the selected semantic model using a token-based connection and SHALL NOT require credentials embedded in the RDL.

#### Scenario: Missing model identity
- **WHEN** the workspace or semantic model GUID cannot be resolved
- **THEN** generation or publication SHALL stop with a clear request for the missing identity rather than producing an unbound report

#### Scenario: Model-bound report generation
- **WHEN** a valid workspace and semantic model identity are available
- **THEN** the generated RDL contains a semantic-model data source using the model GUID and no username, password, or access token

### Requirement: Generate schema-valid RDL from DAX-backed datasets

The skill SHALL support generating an RDL containing DAX datasets, correctly mapped fields and data types, report parameters, filters, grouped tablix/detail layouts, totals, and page header/footer content. It SHALL preserve required RDL namespaces and element ordering and SHALL validate XML well-formedness before publication.

#### Scenario: Detail and parameter datasets
- **WHEN** a user supplies a semantic model schema and requested detail fields and parameter values
- **THEN** the generated RDL contains a detail dataset and value datasets whose field mappings match the DAX result columns, including required bracketing or qualification

#### Scenario: Invalid generated XML
- **WHEN** generated expressions contain malformed XML or required RDL structure is invalid
- **THEN** the workflow reports the validation failure and does not attempt to publish the file

### Requirement: Support report parameters and consistent filtering

The skill SHALL support scalar and multi-value report parameters, valid/default values sourced from datasets where applicable, and date and dimension filtering. KPI and total expressions SHALL use the filtered report dataset scope so displayed aggregates remain consistent with parameter selections.

#### Scenario: Multi-value parameter
- **WHEN** a user requests a multi-select dimension filter
- **THEN** the report exposes a multi-value parameter with valid values and applies an `In` filter to the relevant dataset or tablix

#### Scenario: Text date field
- **WHEN** a requested date filter targets a text-typed model field
- **THEN** the workflow identifies the type limitation and converts or otherwise handles the field explicitly before applying a date range

### Requirement: Publish and verify paginated reports safely

The skill SHALL publish a validated `.rdl` to the requested workspace using an authenticated supported upload path, poll asynchronous operations to a terminal success or failure state, and report the resulting report identifier and web URL without exposing tokens. On definition-format failure, it SHALL surface the error and use the supported alternate upload path when available rather than retrying the same invalid payload.

#### Scenario: Successful first publication
- **WHEN** a validated RDL is uploaded to a workspace with a resolvable semantic model
- **THEN** the workflow waits for publication completion and reports the created report ID and web URL

#### Scenario: Publication failure
- **WHEN** publication fails or times out
- **THEN** the workflow reports the terminal operation state and actionable error details, and SHALL NOT claim that the report was created

### Requirement: Preserve reproducibility and security

The skill SHALL retain the generator and publishing scripts as reusable assets, document required tools and permissions, avoid hardcoded workspace/model IDs and secrets, and provide offline tests for generator and discovery metadata behavior.

#### Scenario: Re-publish an existing report
- **WHEN** a user changes the report inputs and requests a re-publication
- **THEN** the same persisted generator inputs/scripts can reproduce the RDL and the workflow uses an explicit overwrite policy only after the report exists

#### Scenario: Secret handling
- **WHEN** authentication or publication diagnostics are emitted
- **THEN** tokens and credentials are read from approved authentication mechanisms and are absent from generated files, console output, and logs
