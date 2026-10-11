## Purpose

Defines a clear planning-only workflow for new Power BI report requests and a tested handoff from business discovery to the architect's developer-executable specification.

## ADDED Requirements

### Requirement: Planning workflow stops at an approved brief

The report planning workflow SHALL gather business requirements, inspect available semantic-model context, define report scope and page intent, capture design direction, record dependencies, and produce an approved planning brief. After the brief is approved, the workflow SHALL stop and SHALL NOT implement model, report, PBIR, publishing, or deployment changes.

#### Scenario: New report request enters planning
- **WHEN** a user requests a new Power BI report or dashboard and the planning workflow is selected
- **THEN** the workflow SHALL conduct requirements and planning rounds and produce a planning brief for approval

#### Scenario: Planning brief is approved
- **WHEN** the user approves the planning brief
- **THEN** the workflow SHALL present the architect handoff, including the exact path of `brief.md`, and stop without invoking implementation or publishing execution

#### Scenario: User asks planning to build immediately
- **WHEN** a planning workflow request also asks for implementation in the same interaction
- **THEN** the workflow SHALL complete only the planning brief and SHALL require a separate implementation request after the architect specification is ready

### Requirement: Work artifacts live in one folder per work item

The planning workflow and the architect SHALL keep all artifacts of one piece of work in `specs/<JIRA>-<slug>/`, or `specs/<slug>/` when no Jira ticket is available, where `<slug>` is lowercase kebab-case derived from the report or work name. The folder SHALL hold `brief.md`, an optional `mockup/` folder, and the architect's `<Name>.spec.md` with its `<Name>.plan.md` and `<Name>.ExecutionSummary.md`. The Jira ticket SHALL be taken from the current git branch name when present, and otherwise requested from the user once. The `<Name>` of a specification MAY differ from the report name.

#### Scenario: Repository holds more than one report
- **WHEN** a repository contains work for two reports
- **THEN** each report SHALL have its own work folder so that `brief.md` and the specification files never collide

#### Scenario: Branch carries a Jira ticket
- **WHEN** the current branch name contains a Jira ticket key
- **THEN** the folder name SHALL begin with that key followed by the slug

#### Scenario: Work folder already exists
- **WHEN** planning or the architect would write into a folder that already contains `brief.md` for a different report
- **THEN** the workflow SHALL NOT overwrite it and SHALL ask for a different name

#### Scenario: Specification name differs from report name
- **WHEN** the architect names the specification differently from the report
- **THEN** the specification SHALL still be discoverable from the brief and the mock because they share the same work folder

### Requirement: Planning brief is distinct from the implementation specification

The planning workflow SHALL identify its output as a planning brief stored as `brief.md` in the work folder, and SHALL NOT present it as the canonical developer execution specification. The brief SHALL carry front-matter with `jira` (when available), `report`, `status` (`draft` or `approved`), and `mockup` (when supplied), and SHALL capture the approved business context needed by the architect, including audience, purpose, scope, delivery target, model inventory, page intent, design direction, dependencies, constraints, open decisions, and approval status. The brief SHALL be frozen once approved.

#### Scenario: Architect receives an approved planning brief
- **WHEN** the architect is handed an approved planning brief
- **THEN** the architect SHALL be able to identify the report goal, model context, scope, page intent, design direction, delivery constraints, and unresolved risks without reconstructing the business conversation

#### Scenario: Planning brief lacks implementation tasks
- **WHEN** the planning brief is reviewed for implementation readiness
- **THEN** it SHALL be treated as an input to architecture and SHALL NOT be marked complete merely because it contains visual design YAML or page layout details

### Requirement: Approved design mock is an optional, non-gating planning input

The planning workflow SHALL accept an optional, user-finalized HTML design mock as an input to its design step. User sign-off on the mock SHALL count as design approval, and planning approval SHALL then cover scope, field bindings, and translation notes rather than re-opening layout or visual choices. The mock SHALL NOT be required by planning, the architect, or the developer.

#### Scenario: Mock is supplied and signed off
- **WHEN** the user supplies a finalized mock
- **THEN** planning SHALL derive the `Design Brief:` through `powerbi-report-design`, record the mock path in the brief, and SHALL NOT re-ask design direction the mock already answers

#### Scenario: Mock elements cannot be built as drawn
- **WHEN** deriving the design contract exposes elements that fail the design contract gate
- **THEN** planning SHALL report them as translation notes for approval rather than starting a redesign

#### Scenario: Mock fields have no model counterpart
- **WHEN** a mock element has no matching field or measure in the semantic model
- **THEN** planning SHALL record it as a model requirement in the brief so the architect can plan the work

#### Scenario: No mock exists
- **WHEN** the user has no design mock
- **THEN** planning SHALL run its normal design step through `powerbi-report-design`

### Requirement: Architect produces the canonical developer specification

The architect workflow SHALL produce the canonical `<Name>.spec.md` in the work folder using the repository's established specification contract. For a new report or dashboard, the architect SHALL consume an approved `brief.md` and SHALL NOT produce the specification without one; specifications that do not involve a new report, such as model-only specifications, are exempt. The canonical specification SHALL include an overview, EARS-style requirements and acceptance criteria, design and architecture, data sources and model/report components, deployment or validation boundaries, a `Revisions` section, and a concrete `Tasks` section with traceability to requirements, and SHALL carry front-matter with `jira` (when available), `report`, `status`, and `mockup` (when supplied).

#### Scenario: Architect receives an approved brief
- **WHEN** the architect begins work from an approved planning brief
- **THEN** the architect SHALL create `<Name>.spec.md` in the brief's work folder and SHALL preserve the approved scope while filling technical and execution details

#### Scenario: New report request arrives without a brief
- **WHEN** the architect is asked for a new report specification and no approved brief exists
- **THEN** the architect SHALL route the request to the planning workflow first

#### Scenario: Model-only specification
- **WHEN** the architect is asked for a specification that does not create a new report
- **THEN** the architect SHALL proceed without a brief and SHALL create the work folder itself

#### Scenario: Architect creates implementation tasks
- **WHEN** the canonical specification contains implementation work
- **THEN** each task SHALL be concrete enough for `powerbi-developer` to execute autonomously and SHALL identify applicable requirements or acceptance criteria

### Requirement: Embedded Design Brief is the sole authoritative design

The architect SHALL embed the approved `Design Brief:` YAML verbatim in the specification under `Design > Report Design Contract`, and SHALL NOT rewrite it. EARS requirements SHALL cite the embedded contract, and the Tasks section SHALL contain one task per report page whose acceptance criteria are conformance to that page's `layout_contract`. After embedding, the specification's YAML SHALL be the only authoritative design; the brief and any mock are non-authoritative references. Changes to the design SHALL be made by regenerating the block through `powerbi-report-design` and recording the change in the `Revisions` section.

#### Scenario: Specification is created from a brief with a design contract
- **WHEN** the architect writes the specification for a report with a Design Brief
- **THEN** the specification SHALL contain the YAML verbatim, requirements citing `pages[]`, `placements`, and `space_audit`, and one task per page

#### Scenario: Specification and brief differ
- **WHEN** the embedded YAML and the brief's design content differ after the specification is created
- **THEN** the specification's YAML SHALL prevail

#### Scenario: Revised mock is used to update the specification
- **WHEN** a user or developer asks the architect to update the specification from a revised mock
- **THEN** the architect SHALL derive the design contract through `powerbi-report-design`, replace the embedded block, record the delta as ADDED, MODIFIED, or REMOVED entries in `Revisions`, and update the recorded mock provenance

#### Scenario: Design changes after execution has started
- **WHEN** a revision affects pages whose tasks are already complete
- **THEN** the architect SHALL append new tasks for the delta and SHALL NOT reset or silently alter completed tasks

### Requirement: Developer consumes the embedded design contract

When implementing report-page tasks, `powerbi-developer` SHALL extract the embedded `Design Brief:` block from the specification and pass it to `powerbi-report-authoring`. If the block is missing, the developer SHALL stop the report-page task and ask the architect instead of improvising layout. Layout changes SHALL be routed to the architect as a specification update. The developer SHALL derive plan and execution-summary paths from the folder of the specification it was given, and its existing contract of finding a `Tasks` section, validating each task against acceptance criteria, and producing an execution summary SHALL remain.

#### Scenario: Report-page task has an embedded contract
- **WHEN** the developer executes a report-page task and the specification contains the Design Brief block
- **THEN** it SHALL implement the page per that page's `layout_contract` and validate it against the task's acceptance criteria

#### Scenario: Specification has no embedded contract
- **WHEN** the developer is asked to implement report pages and the specification has no Design Brief block
- **THEN** it SHALL leave the task unchecked and request that the architect add the contract

#### Scenario: Developer wants a layout change
- **WHEN** a layout change is needed during implementation
- **THEN** the developer SHALL ask the architect to update the specification and SHALL NOT change the layout on its own

#### Scenario: Developer writes derived files
- **WHEN** the developer creates a plan or execution summary
- **THEN** it SHALL write them next to the specification in the same work folder

### Requirement: Specialist ownership remains explicit

The workflow SHALL route responsibilities consistently: planning owns business discovery and approval, architecture owns the canonical technical specification, report design owns visual design guidance, report authoring owns PBIR mechanics, semantic-model authoring owns model-definition changes, report management owns Fabric report CRUD, and the developer owns implementation and validation execution.

#### Scenario: Request concerns visual design only
- **WHEN** a user asks for open-ended visual design or redesign without requirements-to-build planning
- **THEN** the request SHALL route to `powerbi-report-design` without requiring the full planning workflow

#### Scenario: Approved report requires implementation
- **WHEN** an approved planning brief has been converted into a canonical specification
- **THEN** implementation SHALL route through `powerbi-developer` and the specialist skills named by the specification rather than through the planning workflow

### Requirement: The process is documented for users

The plugin README and the repository README SHALL describe the end-to-end process: optional design mock, planning, architect specification with the embedded design contract, and developer implementation, together with the work-folder layout and the ownership of each step. The documentation SHALL describe the design mock as optional and SHALL NOT present mock generation, ingestion, or binding mechanics as available until they are delivered.

#### Scenario: Developer reads the plugin README
- **WHEN** a user reads the Power BI plugin README
- **THEN** it SHALL show the planning, architect, and developer flow, the work-folder layout, and which agent owns each artifact

#### Scenario: Mock mechanics are not yet delivered
- **WHEN** the README describes the design mock
- **THEN** it SHALL present the mock as an optional input and SHALL NOT claim generator or ingestion tooling

### Requirement: The workflow SHALL be fully loadable in GitHub Copilot

The plugin packaging and setup guidance SHALL distinguish successful plugin discovery
from successful skill loading. Non-interactive verification SHALL use `copilot plugin
list`, interactive verification MAY use `/plugin list`, and the validation path SHALL
also inspect `copilot skill list`. Every bundled skill description SHALL remain within
GitHub Copilot's 1,024-character frontmatter limit so that the installed plugin exposes
all declared skills.

#### Scenario: Copilot discovers the plugin
- **WHEN** the setup completes for GitHub Copilot
- **THEN** `copilot plugin list` SHALL show the installed plugin and its expected version

#### Scenario: A bundled skill is rejected during loading
- **WHEN** `copilot skill list` reports a skill-load failure for a bundled skill
- **THEN** the plugin SHALL NOT be declared healthy, and the failure SHALL identify the
  rejected skill and the frontmatter constraint that must be corrected

#### Scenario: Copilot setup documentation is followed
- **WHEN** a user follows the documented non-interactive verification command
- **THEN** the command SHALL be valid for the installed Copilot CLI and SHALL not rely on
  passing `/plugin list` as a top-level executable argument

### Requirement: Power BI MCP setup is portable and readiness-validated

The setup workflow SHALL provision the pinned Power BI Modeling MCP package for
the current user through the available Node.js/npm runtime, SHALL preserve a
portable repository source declaration, and SHALL generate a host-specific MCP
launch definition without requiring the VS Code extension or an absolute
extension-installation path. On Windows x64, the generated definition SHALL use
`node.exe` with npm's `npx-cli.js` and the pinned platform package rather than
the `npx.cmd` batch shim. Setup SHALL distinguish package provisioning and
plugin discovery from MCP readiness and SHALL perform a bounded MCP
`initialize` check before reporting the connector ready.

#### Scenario: First user installs the Power BI MCP
- **WHEN** a user runs the Power BI plugin setup and the pinned package is not in
  the user's npm cache
- **THEN** setup SHALL download and provision the pinned package for that user,
  retain the portable source declaration in the repository, and generate the
  selected host's MCP configuration

#### Scenario: User reruns setup with a cached package
- **WHEN** a user reruns setup and the pinned package is already available in
  that user's npm cache
- **THEN** setup SHALL reuse or validate the cached package without requiring a
  VS Code extension installation, and SHALL still perform the MCP readiness check

#### Scenario: Windows x64 host projection
- **WHEN** setup targets Copilot or another supported host on Windows x64
- **THEN** the generated MCP definition SHALL launch `node.exe` with npm's
  `npx-cli.js`, the pinned `@microsoft/powerbi-modeling-mcp-win32-x64` package,
  and the server start argument, and SHALL NOT use `npx.cmd`

#### Scenario: MCP process fails initialization
- **WHEN** package provisioning succeeds but the MCP process cannot complete a
  bounded `initialize` exchange
- **THEN** setup SHALL report the connector as not ready and SHALL include the
  generated command and actionable remediation rather than claiming successful
  MCP setup

### Requirement: Installer dependencies and backups SHALL be managed conditionally

The setup workflow SHALL discover whether the required ADOMD.NET dependency is
already available and usable before attempting installation. It SHALL reuse a
valid available dependency, and SHALL install or repair it only when discovery
confirms that it is missing or unusable. The workflow SHALL remove installer
backup artifacts older than seven days relative to the cleanup run, SHALL
preserve artifacts at or newer than that boundary, and SHALL treat a missing
backup location as a successful no-op.

#### Scenario: Required ADOMD.NET dependency is available
- **WHEN** setup discovers a usable ADOMD.NET installation that satisfies the
  required version or capability
- **THEN** setup SHALL reuse it without downloading or reinstalling ADOMD.NET

#### Scenario: Required ADOMD.NET dependency is unavailable
- **WHEN** setup cannot discover a usable ADOMD.NET installation
- **THEN** setup SHALL install the required dependency and report the
  provisioning result

#### Scenario: Backup cleanup runs with mixed ages
- **WHEN** setup cleans a backup location containing artifacts older than seven
  days and artifacts at or newer than seven days
- **THEN** setup SHALL delete only the older artifacts and SHALL preserve the
  current artifacts

#### Scenario: Backup location is absent
- **WHEN** setup runs cleanup and the backup location does not exist
- **THEN** setup SHALL report cleanup as a successful no-op and SHALL continue
  the installation workflow

### Requirement: Codex MCP registration SHALL respect ownership

When setup projects the Power BI MCP definition to Codex, it SHALL create the
registration when it is absent and SHALL update it when the existing
`powerbi-modeling-mcp` entry is marked as installer-owned. If an entry with that
name exists without the installer ownership marker, setup SHALL not remove,
rename, or overwrite it automatically; it SHALL fail the Codex installation
step with the conflicting name and actionable instructions to remove or rename
the entry before retrying.

#### Scenario: Codex MCP registration is absent
- **WHEN** setup targets Codex and no `powerbi-modeling-mcp` registration exists
- **THEN** setup SHALL create the registration with the installer ownership
  marker and the generated host-specific definition

#### Scenario: Existing Codex registration is installer-owned
- **WHEN** setup targets Codex and an existing `powerbi-modeling-mcp`
  registration contains the installer ownership marker
- **THEN** setup SHALL update it to the current generated definition

#### Scenario: Existing Codex registration is not installer-owned
- **WHEN** setup targets Codex and an existing `powerbi-modeling-mcp`
  registration lacks the installer ownership marker
- **THEN** setup SHALL leave it unchanged and report that the user must remove
  or rename it before installation can continue
