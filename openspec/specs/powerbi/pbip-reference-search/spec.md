## Purpose

Defines when the local PBIP reference-search workflow must be selected for a user's request and how it must correlate and classify table and field matches so that reference-search results are trustworthy rather than merely keyword-based.

## Requirements

### Requirement: Skill Discoverability for Reference-Search Requests
The `powerbi-report-authoring` skill's discovery metadata SHALL describe reference-search as a first-class use of the skill, independent of rename/removal framing, and SHALL include the trigger phrases "find all references", "where is this field used", "find reports using", and "scan PBIP dependencies".

#### Scenario: Skill triggers on a plain reference-search request
- **WHEN** a user asks "find all references to Region from table Sims HFI_ClientInfo across all reports" without naming any tool or skill
- **THEN** the `powerbi-report-authoring` skill SHALL be selected on that first prompt

#### Scenario: Skill triggers on field-usage phrasing without the word "reference"
- **WHEN** a user asks "where is this field used?" about a specific column or measure in a PBIP project
- **THEN** the `powerbi-report-authoring` skill SHALL be selected on that first prompt

### Requirement: Reference-Search Routing Precedes Generic Search
When a request concerns references, usages, dependencies, or rename impact for a table, column, measure, field, visual, or filter in a local PBIP project, the workflow SHALL select the bundled reference scanner (`report_reference_scan.ps1` / `report_reference_scan.py`) before falling back to generic repository-wide text search. Generic text search SHALL only be used afterward, to inspect or verify scanner results.

#### Scenario: Scanner is selected before generic search
- **WHEN** a user asks which reports depend on a named semantic-model table or column
- **THEN** the workflow SHALL run the reference scanner against the PBIP root before issuing any generic text search over the repository

#### Scenario: Generic search is used only to verify a scanner result
- **WHEN** the workflow needs to double-check the exact surrounding context of a scanner hit
- **THEN** it MAY use generic text search on the specific file identified by the scanner, and SHALL NOT substitute that verification step for the initial scan

### Requirement: Multi-Term Scanner Invocation Safety
When a reference-search request supplies more than one scanner term (for example a table/entity name and a field/measure name), the workflow SHALL pass all terms to `report_reference_scan.ps1` as a single explicit array argument bound to `-Terms`, and SHALL NOT pass multiple bare positional values after `-Terms` that could bind to another parameter such as `-MaxItems`.

#### Scenario: Two-term scan uses an explicit array
- **WHEN** the workflow scans for both a table name and a field name in the same invocation
- **THEN** it SHALL construct an array variable containing both terms and pass it as the `-Terms` argument, and the resulting invocation SHALL NOT alter the value of `-MaxItems` or any other parameter

### Requirement: Table-Field Match Correlation and Classification
When a reference-search request names both a table/entity and a field/measure within that table, the workflow SHALL classify every scanner hit into exactly one of the following categories before reporting it:
- **Exact qualified reference**: the field match is directly paired with the requested table in the same artifact — for a PBIR hit, a `queryRef` value whose leading component equals the requested table and whose trailing component equals the requested field (including hierarchy-qualified `queryRef` forms); for a TMDL hit, a field/measure/calculated-column hit whose recorded containing table equals the requested table.
- **Table-only reference**: the requested table/entity matches in an artifact, but no hit in that same artifact satisfies the exact-qualified condition for the requested field.
- **Unrelated match**: the requested field name matches in an artifact whose paired or containing table is a different table than the one requested.
The workflow SHALL NOT report a table-only or unrelated match as an exact qualified reference.

#### Scenario: queryRef pairing produces an exact qualified reference
- **WHEN** a PBIR hit's `queryRef` value is `"Sims HFI_ClientInfo.Region"` and the request is for `Region` on table `Sims HFI_ClientInfo`
- **THEN** the workflow SHALL classify that hit as an exact qualified reference

#### Scenario: Table name present without the requested field is table-only
- **WHEN** a report file contains an `Entity` match for `Sims HFI_ClientInfo` but no `queryRef`, `Property`, or TMDL hit in that same file pairs `Region` with that table
- **THEN** the workflow SHALL classify that file's match as table-only and SHALL NOT present it as evidence that `Region` is used there

#### Scenario: Same-named field from a different table is unrelated
- **WHEN** a TMDL hit reports a column named `Region` whose containing table is `Geography`, not the requested `Sims HFI_ClientInfo`
- **THEN** the workflow SHALL classify that hit as an unrelated match

#### Scenario: Entity and Property matches without a queryRef pairing are downgraded
- **WHEN** a PBIR file contains an `Entity` match for the requested table and a separate `Property` match for the requested field on different lines, but no `queryRef` value pairs them as `<table>.<field>`
- **THEN** the workflow SHALL classify the combination as table-only rather than exact qualified, pending confirmation from a `queryRef` pairing or direct file inspection

### Requirement: Single-Term Reference Search Remains Supported
The workflow SHALL support a reference-search request that names only a table/entity or only a field/measure, without requiring the user to supply both. The three-way classification in the Table-Field Match Correlation and Classification requirement applies only when both a table and a field are named; for a single-term request, the workflow SHALL run the scanner for that one term and report every resulting hit as a direct match, without withholding, downgrading, or fabricating a table/field pairing that the request did not ask for.

#### Scenario: Table-only request returns all matches for that table
- **WHEN** a user asks "which reports depend on the Sims HFI_ClientInfo table" without naming a specific column or measure
- **THEN** the workflow SHALL scan for the single term `Sims HFI_ClientInfo` and report every semantic-model and report hit for that table, without requiring a paired field match

#### Scenario: Field-only request returns all matches for that field
- **WHEN** a user asks "find all references to Region" without naming a table
- **THEN** the workflow SHALL scan for the single term `Region` and report every semantic-model and report hit for that field across all tables, without classifying any hit as table-only or unrelated for lack of a table term

### Requirement: Result Reporting Distinguishes Match Categories
When a reference-search request names both a table/entity and a field/measure, the workflow's response SHALL report exact qualified references first, grouped by report and page/visual where available, and SHALL report table-only references and unrelated matches in separate, clearly labeled sections rather than merging them into the exact-reference list. For a single-term request, the response SHALL report all matches for that term directly, without the exact/table-only/unrelated split.

#### Scenario: Two-term response separates the three categories
- **WHEN** a reference-search scan for both a table and a field produces exact qualified, table-only, and unrelated hits
- **THEN** the response SHALL present them as three distinct sections, each labeled with its category

#### Scenario: Single-term response is not split into categories
- **WHEN** a reference-search scan runs for a single table-only or field-only term
- **THEN** the response SHALL list all resulting hits directly, without inventing table-only or unrelated sections that the single-term request has no basis to distinguish

### Requirement: Read-Only Reference Scan
Performing a reference search SHALL NOT modify any PBIP, TMDL, PBIR, or other workspace file.

#### Scenario: Workspace is unchanged after a scan
- **WHEN** the workflow completes a reference-search request, including correlation and classification
- **THEN** no file in the scanned PBIP project SHALL have been created, modified, or deleted as a result
