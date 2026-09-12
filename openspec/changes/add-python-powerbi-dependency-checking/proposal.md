## Why

Power BI architecture, refactoring, and test planning currently rely on manual inspection to discover which reports, measures, columns, and semantic-model objects use one another. A reusable, Python-based static dependency scanner will let any Power BI workflow detect impact and unused objects from local PBIP source before making a change, without needing Power BI Desktop or a Fabric connection.

## What Changes

- Add a standalone `powerbi-dependency-checking` skill to `plugins/powerbi/skills/`, centered on a Python static-analysis script for local PBIP projects.
- Parse TMDL semantic-model definitions and PBIR report definitions to build a directed dependency graph across reports, visuals, measures, calculated columns, hierarchies, relationships, partitions, perspectives, and roles where source references are statically available.
- Provide impact queries for a named model object, including direct consumers, transitive consumers, dependency paths, and report/visual usage.
- Detect potentially unused objects using reachability from report and governance roots, and explain each finding's known consumer state rather than treating it as a safe deletion instruction.
- Emit stable human-readable, JSON, and quiet/exit-code outputs so the scanner is useful interactively and in CI.
- Route architecture, semantic-model authoring, report authoring, and DAX unit-testing workflows to this skill before rename/removal, dependency-sensitive changes, or coverage-impact review.

## Capabilities

### New Capabilities
- `powerbi/dependency-checking`: Python static analysis for local PBIP projects that builds and queries a model/report dependency graph, identifies potentially unused objects, and provides stable interactive and CI output.

### Modified Capabilities
<!-- none: existing main OpenSpec specs have not been archived yet; workflow routing changes are implementation/documentation integration for this new capability -->

## Impact

- New: `plugins/powerbi/skills/powerbi-dependency-checking/`, including its `SKILL.md`, Python scanner, parser modules, fixture PBIP project, and tests.
- Modified: `plugins/powerbi/skills/semantic-model-authoring/SKILL.md`, `plugins/powerbi/skills/powerbi-report-authoring/SKILL.md`, `plugins/powerbi/skills/dax-unit-testing/SKILL.md` (once implemented), `plugins/powerbi/agents/powerbi-architect.agent.md`, `plugins/powerbi/agents/powerbi-developer.agent.md`, `plugins/powerbi/README.md`, `AGENTS.md`, and `CLAUDE.md` to surface and route the new capability.
- Informed by ripbi's local-PBIP, static-analysis model and output contract; this change implements an independent Python tool rather than vendoring or depending on ripbi's Rust binary.
- Scope is limited to local `.pbip` projects, `.SemanticModel`, and `.Report` directories. `.pbix`, `.pbit`, live Desktop models, and tenant-wide scanning are excluded.
