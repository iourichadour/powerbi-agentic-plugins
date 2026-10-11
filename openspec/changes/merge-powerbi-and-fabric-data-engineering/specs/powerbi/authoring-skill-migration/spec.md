## Purpose

Provide a cohesive Power BI authoring skill suite that preserves local strengths, adopts reviewed upstream improvements, and routes each request to one authoritative capability.

## ADDED Requirements

### Requirement: Power BI authoring concerns have explicit owners

The system SHALL route PBIR/PBIP pages, visuals, formatting, templates, validation, rendering, and local report-reference scanning to report authoring. It SHALL route report item CRUD and definition transport to report management, requirements and build sequencing to report planning, open-ended visual design to report design, and semantic-model definition changes to semantic-model authoring.

#### Scenario: Report visual formatting request

- **WHEN** a user requests a change to a report visual, page, theme, filter, or slicer
- **THEN** the system routes the request to report authoring without treating it as report item CRUD or semantic-model editing

#### Scenario: Fabric report publication request

- **WHEN** a user requests to create, upload, download, update, list, or delete a Fabric report item or its definition
- **THEN** the system routes the request to report management without using report authoring as the transport owner

### Requirement: Local Power BI capabilities are preserved during selective merges

The system SHALL preserve local Power BI-only skills, bundled scripts, templates, reference scanning, DAX testing, and Power BI agents unless a reviewed migration decision explicitly replaces or removes them. Upstream content SHALL be adopted only when it improves the assigned owner's behavior without creating a phantom dependency or duplicating an existing local capability.

#### Scenario: Upstream content has no local dependency support

- **WHEN** upstream skill text references a companion skill, script, asset, or configuration that is not installed by the approved change
- **THEN** the system excludes or adapts that text rather than retaining a broken reference

#### Scenario: Local report authoring resource is unique

- **WHEN** a local report-authoring script, template, or reference has no equivalent upstream resource
- **THEN** the system retains it and verifies its routing remains valid after the merge

### Requirement: Selective merge decisions are evidence-based and reviewed

The system SHALL evaluate each matched local and upstream skill pair with the `skill-merge-planner` seven-dimension quality rubric and live objective validation before selecting a merge direction. It SHALL separately inventory references, scripts, and assets, record the validation result and rubric drivers, and obtain a user-confirmed disposition. The score SHALL guide, rather than automatically determine, the selected base.

#### Scenario: Matched skill pair is evaluated

- **WHEN** a local Power BI skill is compared with an upstream counterpart
- **THEN** the system records both seven-dimension scores, live validation results, unique-resource inventory, recommended disposition, and the user's confirmed or overridden disposition before implementation begins

#### Scenario: Candidate contains a broken dependency

- **WHEN** validation fails or a candidate references an unavailable companion skill, script, asset, or configuration
- **THEN** the system treats that result as a constraint on the relevant quality assessment and excludes or adapts the dependency before the merge is approved

### Requirement: FabricIQ and data-engineering routing is coordinated

The system SHALL route natural-language questions over existing Power BI report or semantic-model data to FabricIQ only after its companion capability is installed and verified. It SHALL route cross-workload Fabric data engineering and migration requests to the selected Fabric Data Engineer or Migration Engineer capability without changing the ownership of Power BI authoring work.

#### Scenario: Business question over report data

- **WHEN** a user asks for a business insight or value from an existing Power BI report
- **THEN** the system routes the request to verified FabricIQ consumption guidance and does not attempt to create or modify report definitions

#### Scenario: FabricDataEngineer needs semantic-model work

- **WHEN** a cross-workload data-engineering workflow requires a semantic-model definition change
- **THEN** the system delegates that portion to semantic-model authoring while retaining the Data Engineer as the cross-workload orchestrator

### Requirement: Power BI guidance is progressively disclosed across supported harnesses

The system SHALL make the selected Power BI skills and agents discoverable in Codex, Claude Code, and GitHub Copilot CLI using shared source-owned content. A request SHALL load only its selected skill and on-demand references, rather than the entire Power BI or Fabric guidance collection.

#### Scenario: Targeted report-planning request

- **WHEN** a user requests requirements gathering and build sequencing for a new report
- **THEN** the system loads report planning guidance and only the report-design or authoring resources that planning explicitly requires

#### Scenario: Installed skill references a local resource

- **WHEN** a selected Power BI skill is installed in a supported harness
- **THEN** its referenced local scripts, templates, and guidance resolve from the same source-owned package without duplicated skill bodies
