---
jira: <JIRA key or null>
report: <Report name>
status: draft # draft | approved
mockup: <relative mock path or null>
---

# Planning Brief: <Report name>

## Business context

- Audience:
- Primary purpose / decision supported:
- Success criteria:
- Delivery target:

## Semantic-model inventory

- Model / source:
- Known tables, grain, and keys:
- Dimensions and measures available:
- Data caveats and risks:

## Scope and page intent

- Included scope:
- Deferred scope:
- Global slicers and interactions:

### Page 1: <Name>

- Purpose:
- Key questions answered:
- Intended visuals and fields:

## Design direction

- Archetype / composition:
- Tone and signature:
- Theme, accessibility, and interaction guidance:
- Mock translation notes: <or none>

## Design Brief

<!-- Paste the exact fenced `yaml` block produced by powerbi-report-design when available. -->

## Model requirements

- Missing fields or measures required by the report:
- Relationship, sort, or calculation requirements:

## Dependencies and constraints

- Dependencies:
- Tooling / access constraints:
- Publishing boundary:
- Risks:

## Open decisions

- <Decision or none>

## Approval

- Planning approved by:
- Approved date:
- Approval notes:

## Architect handoff

- Canonical specification path: `<Name>.spec.md` in this folder
- Required architecture work:
- Spec-name rationale when it differs from the report name:

## Pre-approval completeness checklist

- [ ] Audience, purpose, and success criteria are known.
- [ ] Semantic-model inventory and data risks are recorded.
- [ ] Scope and page intent are explicit.
- [ ] Design direction and accessibility needs are captured.
- [ ] Missing field bindings are recorded as model requirements.
- [ ] Dependencies, constraints, risks, and open decisions are recorded.
- [ ] Optional mock path and translation notes are recorded when supplied.
- [ ] The brief is ready for architect approval and contains no implementation task list.
