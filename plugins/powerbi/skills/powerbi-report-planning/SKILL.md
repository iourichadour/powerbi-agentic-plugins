---
name: powerbi-report-planning
description: >-
  Plan a new Power BI report or dashboard through business discovery, semantic-model
  inspection, report scope, page intent, design direction, dependencies, and approval.
  Use when a user needs a planning brief before a Power BI report specification is
  designed. Produces an approved brief for `powerbi-architect`; it never implements,
  validates, deploys, or publishes a report. For direct PBIR edits use
  `powerbi-report-authoring`; for design-only work use `powerbi-report-design`.
  Triggers: "plan a Power BI report", "report requirements", "plan a dashboard",
  "report discovery", "report brief", "define report scope".
metadata:
  version: 0.2.0
---

> **Update Check — explicit only**
> Only run **check-updates** when the user explicitly asks to check for updates.

# Power BI Report Planning

This is a planning-only gate for a new Power BI report.

**Discover -> Inspect -> Design direction -> Approve brief -> Hand off**

The architect owns the canonical technical specification. The developer owns
implementation and validation. Do not invoke authoring, model-editing, deployment,
or publishing workflows from this skill.

## Must / Prefer / Avoid

### MUST

- Use this skill for broad new-report discovery that needs business requirements,
  semantic-model context, page intent, design direction, dependencies, and approval.
- Ask focused clarification questions one at a time; do not re-ask facts available in
  the prompt, model, existing PBIP files, or prior answers.
- Inspect available semantic-model context before finalizing scope or field bindings.
- Route visual design through `powerbi-report-design` and create an approved planning
  brief at the exact work-folder path described below.
- Stop once the user approves `brief.md`, state its exact path, and hand off to
  `powerbi-architect`.

### PREFER

- Infer a Jira key from the current git branch; ask once only when no key is present.
- Derive a lowercase kebab-case slug from the report name.
- Treat an approved HTML design mock as useful design evidence, not as a prerequisite.

### AVOID

- Do not implement semantic-model, PBIR, report, validation, deployment, or publishing
  changes.
- Do not create developer task checklists or present `brief.md` as the implementation
  specification.
- Do not use this workflow for design-only work, surgical report edits, semantic-model
  work, or report-management requests.
- Do not claim mock generation, ingestion, or binding tooling exists.

## Workflow

### 1. Establish the work folder

Create one folder per work item:

```text
specs/<JIRA>-<slug>/
  brief.md
  mockup/                 # optional, user-supplied design mock
  <Name>.spec.md          # later, owned by powerbi-architect
  <Name>.plan.md          # later, owned by powerbi-developer
  <Name>.ExecutionSummary.md
```

Use `specs/<slug>/` when a Jira key is unavailable. Read the current branch name for
a Jira key first; if none is discoverable, ask the user once. Before writing, verify
that an existing `brief.md` belongs to the same report. Never overwrite a different
work item's brief.

### 2. Discover requirements and model context

Ask only the questions needed to establish audience, business decision, success
criteria, delivery target, scope, and page intent. Inspect the semantic model using
the available semantic-model capability or local TMDL/PBIP files. Record known tables,
grain, dimensions, measures, field-binding gaps, risks, and model requirements; do not
invent schemas or fields.

Record dependency availability, but use it only to identify planning risks:

- semantic model or PBIP/PBIR source
- model-authoring capability when model changes are needed
- report-authoring capability for later PBIR work
- Desktop preview and publishing access when those are later desired

### 3. Establish page intent and design direction

Use `powerbi-report-design` for archetype selection, design identity, accessibility,
and the structured `Design Brief:` contract. Capture the report's page intent,
visual/field intent, slicers and interactions, and design direction in the brief.

When a user supplies a finalized HTML design mock:

- Treat sign-off on the mock as design approval.
- Do not re-ask visual choices already answered by the mock.
- Derive the `Design Brief:` through `powerbi-report-design` and record translation
  notes for elements that cannot be built as drawn.
- Record fields with no model counterpart as model requirements.
- Store its path in the brief front matter when supplied.

The mock is optional and non-gating. Its later revision changes the canonical design
only when the architect is asked to update the specification.

### 4. Create and approve the planning brief

Copy [`assets/templates/brief.md`](assets/templates/brief.md) to the selected work
folder and fill it with the approved business context. Include the exact `Design Brief:`
YAML produced by `powerbi-report-design` when a report design contract is available;
it is planning input only until embedded verbatim in the architect's specification.

Before approval, confirm that the brief covers audience and purpose, semantic-model
inventory, scope and page intent, design direction, model requirements, dependencies,
constraints, risks, open decisions, and mock translation notes when applicable.

Ask one focused approval question:

> Approve this planning brief for architecture?

On approval, set `status: approved`, freeze the brief, and respond with:

```text
Planning brief approved: specs/<JIRA>-<slug>/brief.md
Next step: ask powerbi-architect to create the canonical implementation specification.
```

Do not start implementation in the same workflow, even if requested. A separate
implementation request begins only after `powerbi-architect` produces the canonical
`<Name>.spec.md`.

## Specialist routing

| Need | Owner |
|---|---|
| Business discovery and approved brief | `powerbi-report-planning` |
| Canonical technical specification and revisions | `powerbi-architect` |
| Visual design guidance and Design Brief | `powerbi-report-design` |
| PBIR mechanics | `powerbi-report-authoring` |
| Semantic-model definition | `semantic-model-authoring` |
| Report CRUD in Fabric | `powerbi-report-management` |
| Implementation and task validation | `powerbi-developer` |
