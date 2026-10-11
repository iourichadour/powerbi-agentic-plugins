## Purpose

Defines a user-controlled Jira routing gate that selects the correct planning
record, preserves resumability, and prevents implementation from starting
without an explicit downstream handoff.

## ADDED Requirements

### Requirement: Jira start SHALL ask the user to classify the work

After Jira assignment, status transition, and branch validation, the workflow
MUST ask the user to select exactly one top-level category: **Bug**, **Report
Development Story**, **Fabric Development**, or **Other**. Jira summary and
description MAY be shown as context, but MUST NOT silently select the category.

#### Scenario: User selects a top-level category

- **WHEN** Jira and branch setup succeeds
- **THEN** the workflow presents the four categories and routes only after the user selects one

#### Scenario: Jira description appears to imply a category

- **WHEN** the Jira summary or description strongly suggests a report, Fabric, bug, or other task
- **THEN** the workflow still asks the user to confirm the top-level category

#### Scenario: User cancels classification

- **WHEN** the user declines or cancels the category prompt
- **THEN** the workflow stops before launching a planning or implementation workflow and reports that routing remains unresolved

### Requirement: Report Development Story SHALL use explicit subtype routing

When the user selects Report Development Story, the workflow MUST ask whether
the work is a new report or dashboard, an existing report change, model-only
work, or report publishing/management.

#### Scenario: New report or dashboard

- **WHEN** the user selects new report or dashboard
- **THEN** the workflow routes to `powerbi-report-planning`, then requires the approved `brief.md` and `powerbi-architect` canonical specification before implementation

#### Scenario: Existing report change

- **WHEN** the user selects an existing report change
- **THEN** the workflow routes to the appropriate report design, report-authoring, or architect path without forcing the new-report planning brief

#### Scenario: Model-only report story

- **WHEN** the user selects model-only work
- **THEN** the workflow routes to semantic-model development and does not require a new-report planning brief

#### Scenario: Report publishing or management

- **WHEN** the user selects report publishing or management
- **THEN** the workflow routes to report-management or the applicable Fabric resource workflow

### Requirement: Fabric Development SHALL use resumable OpenSpec planning

When the user selects Fabric Development for a development, architecture,
migration, or cross-workload change, the workflow MUST create or resume a
Jira-linked OpenSpec change before implementation. The workflow MUST NOT invoke
OpenSpec apply automatically.

#### Scenario: Fabric development has no existing change

- **WHEN** the user selects Fabric Development and no matching Jira-linked OpenSpec change exists
- **THEN** the workflow creates a planning change, reports its path and status, and stops before implementation

#### Scenario: Fabric development has an existing change

- **WHEN** a matching Jira-linked OpenSpec change exists
- **THEN** the workflow surfaces the existing change and resumes it rather than creating a duplicate

#### Scenario: Fabric plan is complete

- **WHEN** the Fabric OpenSpec proposal, requirements, design, and tasks are complete
- **THEN** the workflow reports the completed plan and waits for a separate explicit implementation request before handing off to `FabricDataEngineer` or `FabricMigrationEngineer`

#### Scenario: Fabric request is read-only or operational

- **WHEN** the selected Fabric request is limited to discovery, querying, monitoring, or a simple operational action
- **THEN** the workflow MAY route directly to the applicable Fabric capability without requiring an OpenSpec change

### Requirement: Bug and investigative Other work SHALL maintain troubleshooting records

For Bug and investigative Other work, the workflow MUST read or bootstrap
the repository's `TROUBLESHOOTING.md` before investigation. It MUST resume a
matching ticket section instead of creating a duplicate and MUST require
evidence-based root-cause confirmation before marking the investigation
resolved.

#### Scenario: Troubleshooting log already exists

- **WHEN** Bug or investigative Other work starts and `TROUBLESHOOTING.md` exists
- **THEN** the workflow reads it in full and resumes the matching Jira section or prepares one new section

#### Scenario: Troubleshooting log is absent

- **WHEN** Bug or investigative Other work starts and `TROUBLESHOOTING.md` does not exist
- **THEN** the workflow bootstraps the repository log before investigation continues

#### Scenario: Root cause is confirmed

- **WHEN** a root cause is supported by traced code or data flow and live or equivalent evidence
- **THEN** the workflow updates one ticket-specific section with the symptom, flow, candidates, evidence, root cause, status, and actions

#### Scenario: Resolution creates reusable guidance

- **WHEN** the investigation discovers a reusable connection, diagnostic shortcut, known limitation, prevention rule, or remediation pattern
- **THEN** the workflow updates the shared troubleshooting guidance or environment section after updating the ticket-specific section

#### Scenario: Evidence or connection is unavailable

- **WHEN** the workflow cannot obtain the required evidence or a permitted live connection
- **THEN** it records the blocker in `TROUBLESHOOTING.md` and does not mark the root cause as confirmed

### Requirement: Confirmed fixes SHALL use a surface and size gate

When the user chooses to fix after a confirmed root cause, the workflow MUST
ask for the fix surface (Power BI report, semantic model, Fabric, or Other),
state the intended change, and propose a classification of surgical or
substantial. A fix MUST be proposed as substantial when it renames or removes
an object that has dependents, or introduces a new object or structural change
(such as a new TMDL table, role, calculation group, relationship, or report
page); otherwise it MUST be proposed as surgical. The workflow MUST ask the
user when unsure, and the user confirms or overrides the classification. The
workflow MUST NOT require a new planning record for a surgical fix.

#### Scenario: Surgical fix

- **WHEN** the user chooses to fix and neither substantial trigger applies
- **THEN** the workflow hands off to the applicable specialist with the ticket's `TROUBLESHOOTING.md` section as context, without a new brief, specification, or OpenSpec change

#### Scenario: Rename with dependents

- **WHEN** the intended fix renames or removes an object and the reference scan finds dependents
- **THEN** the workflow proposes a substantial fix and escalates into the existing route for the selected surface, using the troubleshooting section as input

#### Scenario: Rename without dependents

- **WHEN** the intended fix renames an object and the reference scan finds no dependents
- **THEN** the workflow MAY classify the fix as surgical

#### Scenario: New object or structural change

- **WHEN** the intended fix introduces a new object or structural change
- **THEN** the workflow proposes a substantial fix and escalates into the existing route for the selected surface

#### Scenario: User overrides the classification

- **WHEN** the user overrides the proposed classification
- **THEN** the workflow follows the user's classification and records it in the ticket section

#### Scenario: Fix selected but not authorized

- **WHEN** the user selects the fix surface and size
- **THEN** the workflow reports the destination and waits for an explicit implementation request

### Requirement: Non-investigative Other work SHALL pause for user-directed routing

When the user selects Other and the request is not investigative, the workflow
MUST ask the user to specify the affected surface, desired workflow, required
tools, and whether a durable planning record is wanted. It MUST NOT infer an
architecture or implementation route.

#### Scenario: Other request is investigative

- **WHEN** the user identifies Other work as an investigation
- **THEN** the workflow routes it through the troubleshooting record and evidence workflow

#### Scenario: Other request is not investigative

- **WHEN** the user identifies Other work as non-investigative
- **THEN** the workflow pauses for user-directed routing before planning or implementation begins

### Requirement: Planning completion SHALL remain separate from implementation authorization

The workflow MUST report the selected route, current state, required planning
action, and handoff location. Completion of a brief, OpenSpec change,
architect specification, or troubleshooting investigation MUST NOT start
implementation automatically. A later explicit implementation request MUST be
required.

#### Scenario: Planning is incomplete

- **WHEN** a required planning record is missing, incomplete, or not approved
- **THEN** the workflow reports the missing work and refuses implementation changes

#### Scenario: Planning is complete

- **WHEN** the selected route's planning record reaches its defined completion state
- **THEN** the workflow reports the handoff location and waits for an explicit implementation request

#### Scenario: Jira is In Progress but planning is incomplete

- **WHEN** Jira reports In Progress and the ticket branch is valid but planning is incomplete
- **THEN** the workflow permits only the selected planning or investigation activities and refuses implementation

#### Scenario: User explicitly requests implementation

- **WHEN** the planning gate is satisfied and the user explicitly requests implementation
- **THEN** the workflow hands off to the selected implementation agent or specialist with the completed planning record as context

### Requirement: Planning records SHALL be resumable without duplication

Before creating planning state, the workflow MUST search for the route's
existing record and MUST report the exact path and current status of a
matching record.

#### Scenario: Existing Power BI work folder is found

- **WHEN** a matching `specs/<JIRA>-<slug>/brief.md` or canonical specification exists
- **THEN** the workflow surfaces and resumes that report work instead of creating a conflicting folder

#### Scenario: Existing Fabric OpenSpec change is found

- **WHEN** a Jira-linked OpenSpec change matches the selected Fabric work
- **THEN** the workflow surfaces and resumes that change instead of invoking `openspec new change`

#### Scenario: Existing troubleshooting section is found

- **WHEN** `TROUBLESHOOTING.md` contains a matching `## <JIRA>` section
- **THEN** the workflow updates that section in place rather than creating a duplicate

### Requirement: Agent-created commits SHALL update the local session handoff

After every commit performed by the agent, the workflow MUST update
`SESSION_RESUME.md` before continuing with post-commit Jira-comment or
pull-request handling. The handoff MUST record the commit, validation
performed, active planning or implementation state, and next resume point.
`SESSION_RESUME.md` MUST be gitignored, untracked, and never staged or
committed by the workflow.

#### Scenario: Agent creates a commit

- **WHEN** the agent successfully creates a Git commit
- **THEN** it updates the local `SESSION_RESUME.md` with the commit and current handoff before offering Jira comment or PR actions, without staging it

#### Scenario: Handoff file is ignored

- **WHEN** `SESSION_RESUME.md` is updated
- **THEN** `git status` reports no change for it and the working tree is not made dirty by the update

#### Scenario: Jira comment is declined

- **WHEN** the user declines the separate Jira summary-comment offer
- **THEN** the already-updated local `SESSION_RESUME.md` remains the session handoff and no Jira comment is posted

#### Scenario: End-session script stages only publishable files

- **WHEN** `scripts/end-session.ps1` runs
- **THEN** it stages only `MEMORY.md`, declared OpenSpec files, and an explicitly selected Power BI `specs/<JIRA>-<slug>/` recovery folder for report work, never `SESSION_RESUME.md`

#### Scenario: Report recovery folder is selected

- **WHEN** `scripts/end-session.ps1` runs for report work with an explicitly declared `specs/<JIRA>-<slug>/` recovery folder
- **THEN** it stages that folder's changes, including specification status and task-checkbox updates recorded as work completed, without staging unrelated work folders under `specs/` or `SESSION_RESUME.md`

#### Scenario: Only the local handoff changed

- **WHEN** `scripts/end-session.ps1` runs and nothing publishable is staged
- **THEN** it reports that no publishable handoff changes exist instead of failing, and does not commit

#### Scenario: Durable fact learned

- **WHEN** a durable repository convention or gotcha is learned
- **THEN** it is recorded in tracked `MEMORY.md`, not only in `SESSION_RESUME.md`

#### Scenario: Commit validation fails

- **WHEN** validation for the committed work fails or cannot be completed
- **THEN** the workflow records the failure and unresolved next step in `SESSION_RESUME.md` before stopping or asking for direction

### Requirement: Records SHALL have distinct roles and routes SHALL own their recovery record

`MEMORY.md` MUST hold only durable, vendor-neutral facts understandable
without conversation history, and MUST NOT hold ticket status, active
changes, branches, or next steps. `SESSION_RESUME.md` MUST be a local
convenience that no workflow step depends on. Each route's tracked record
MUST be its recovery record: the Power BI `specs/<JIRA>-<slug>/` folder, the
`openspec/changes/<JIRA>-<slug>/` change, or the ticket's `TROUBLESHOOTING.md`
section. Agents MUST update the route's progress markers as work completes.
Fabric OpenSpec changes MUST be matched by the Jira key as the change-name
prefix.

#### Scenario: Durable fact learned

- **WHEN** an agent learns or changes a project fact a new AI harness would need
- **THEN** it records it in `MEMORY.md` in vendor-neutral wording

#### Scenario: In-flight state

- **WHEN** an agent has status, branch, or next-step information
- **THEN** it records it in the route's recovery record or the local `SESSION_RESUME.md`, never in `MEMORY.md`

#### Scenario: Handoff file is lost

- **WHEN** `SESSION_RESUME.md` is missing
- **THEN** the workflow recovers state from the route's recovery record, Jira, `MEMORY.md`, and the user, and does not fail

#### Scenario: Work completes during implementation

- **WHEN** a task or step completes
- **THEN** the agent updates the Power BI spec checkboxes or status, the OpenSpec `tasks.md` checkbox, or the troubleshooting section status

#### Scenario: Fabric change lookup

- **WHEN** resuming Fabric development for a Jira key
- **THEN** the workflow matches OpenSpec changes whose name starts with that key

### Requirement: Existing Jira and branch behavior SHALL remain intact

The routing gate MUST preserve existing Jira assignment, status-transition,
branch-guard, and post-commit Jira-comment behavior. The category gate MUST
not change Jira MCP payloads or infer unavailable transition identifiers.

#### Scenario: Jira and branch setup succeeds

- **WHEN** the existing Jira and branch workflow completes
- **THEN** the routing gate begins without altering the established assignment, status, or branch outputs

#### Scenario: Jira MCP is unavailable

- **WHEN** the Jira MCP is unavailable
- **THEN** the existing Jira fallback remains available and the routing gate still asks the user to classify the work before selecting a downstream workflow

#### Scenario: Agent commits on a Jira branch

- **WHEN** the agent commits while the Jira workflow is active
- **THEN** it preserves the separate Jira summary-comment confirmation and any independent PR offer after updating `SESSION_RESUME.md`
