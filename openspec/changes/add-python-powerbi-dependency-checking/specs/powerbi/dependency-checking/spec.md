## Purpose

Provides a reusable, Python-based static dependency analysis capability for local Power BI PBIP projects so architecture, authoring, testing, and refactoring workflows can understand object usage and change impact before they modify a model or report.

## ADDED Requirements

### Requirement: Supported Local Project Inputs
The dependency checker SHALL accept a local `.pbip` project file, project directory, `.SemanticModel` directory, `.Report` directory, or the current working directory. It SHALL analyze only local PBIP source and SHALL NOT require Power BI Desktop, a Fabric workspace connection, or model credentials.

#### Scenario: Scan a PBIP project file
- **WHEN** a caller passes a local `.pbip` file
- **THEN** the checker SHALL locate and analyze its associated semantic-model and report definitions

#### Scenario: Unsupported binary input fails explicitly
- **WHEN** a caller passes a `.pbix` or `.pbit` file
- **THEN** the checker SHALL fail with an explicit unsupported-input error and SHALL NOT attempt to open the binary file

### Requirement: Static Dependency Graph
The checker SHALL build a directed dependency graph from statically discoverable references in TMDL semantic-model definitions and PBIR report definitions. The graph SHALL represent model objects and report consumers with stable identities and SHALL include measure, calculated-column, hierarchy, relationship, partition, perspective, role, report, page, and visual references where they are available in source.

#### Scenario: Measure dependency is discovered
- **WHEN** a measure expression references another measure
- **THEN** the graph SHALL contain a directed dependency between the two measure identities

#### Scenario: Report visual consumer is discovered
- **WHEN** a PBIR visual references a semantic-model field or measure
- **THEN** the graph SHALL identify that visual and its containing report/page as consumers of the referenced object

### Requirement: Object Impact Query
The checker SHALL accept a model-object identity and return its direct dependencies, direct consumers, transitive consumers, and one or more dependency paths to each transitive consumer. Results SHALL distinguish model consumers from report/page/visual consumers.

#### Scenario: Rename-impact query identifies downstream reports
- **WHEN** a caller queries a measure used by visuals in one or more reports
- **THEN** the checker SHALL return the affected reports, pages, visuals, and dependency paths from each visual to the measure

#### Scenario: Unknown object identity fails explicitly
- **WHEN** a caller queries an object identity that does not exist in the analyzed project
- **THEN** the checker SHALL return a not-found error without returning a partial impact result

### Requirement: Potentially Unused Object Analysis
The checker SHALL identify model objects that are unreachable from configured report and governance roots and SHALL label them as potentially unused. Every finding SHALL state whether it has no known consumer or is consumed only by another potentially unused object. The checker SHALL NOT delete, rewrite, or otherwise modify project files.

#### Scenario: Unreferenced measure is reported as potentially unused
- **WHEN** a measure has no reachable report or governance consumer
- **THEN** the checker SHALL report the measure as potentially unused and explain that no known reachable consumer references it

#### Scenario: Dependency of unused hierarchy is explained
- **WHEN** a column is used only by a hierarchy that is itself potentially unused
- **THEN** the checker SHALL report the column as potentially unused and identify the hierarchy as its only known consumer

### Requirement: Stable Output and Exit Contract
The checker SHALL provide human-readable output, JSON output, and quiet mode. A successful scan with no potentially unused objects SHALL exit with code `0`; a completed scan that finds potentially unused objects SHALL exit with code `1`; and an invalid path, unsupported input, or analysis failure SHALL exit with code `2`. JSON output SHALL include project identity, object counts, roots, reachable counts, unused findings, and graph/impact-query results when requested.

#### Scenario: CI quiet scan reports unused objects by exit code
- **WHEN** a caller runs a quiet scan in CI and potentially unused objects are found
- **THEN** the checker SHALL emit no human-readable scan details and SHALL exit with code `1`

#### Scenario: JSON scan provides machine-readable summary
- **WHEN** a caller requests JSON output for a valid project
- **THEN** the checker SHALL emit a machine-readable summary containing the total object count, root count, reachable count, and potentially unused findings

### Requirement: Shared Workflow Availability
The dependency-checking capability SHALL be independently invocable by architecture, semantic-model authoring, report authoring, and DAX unit-testing workflows. Those workflows SHALL direct callers to run the checker before a rename, removal, dependency-sensitive change, or test-coverage impact review, without making the checker part of any one workflow's implementation.

#### Scenario: Architecture workflow can invoke dependency checking
- **WHEN** an architecture task needs to assess the impact of modifying or removing a Power BI object
- **THEN** the architecture workflow SHALL be able to invoke the dependency checker without invoking the DAX unit-testing workflow

#### Scenario: Dependency check does not alter authoring inputs
- **WHEN** any routed workflow invokes the checker before a change
- **THEN** the checker SHALL leave all PBIP, TMDL, and PBIR source files unchanged
