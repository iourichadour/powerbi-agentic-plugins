## Why

FIN-1810 needs one main behavior contract for the Power BI authoring migration, rather than relying on a standalone comparison plan while related FabricIQ and data-engineering work evolves separately. This main change keeps local Power BI strengths, adopts validated upstream improvements, and coordinates the selected Fabric workstreams without duplicating their detailed implementation contracts.

## What Changes

- Add a main Power BI authoring migration capability covering report authoring, report management, report planning, report design, and semantic-model authoring.
- Preserve local Power BI-only skills, scripts, templates, reference scanning, DAX testing, and agents unless a reviewed migration decision explicitly changes them.
- Require the `skill-merge-planner` seven-dimension rubric, live objective validation, resource inventories, and user-confirmed dispositions before a matched skill pair is merged.
- Define unambiguous routing between report authoring, report management, semantic-model authoring, FabricIQ consumption, and the selected Fabric data-engineering personas.
- Require the migrated Power BI capability to be progressively disclosed and available in Codex, Claude Code, and GitHub Copilot CLI.
- Coordinate, but do not duplicate, the detailed work in `add-fabriciq-consumption-skill` and `port-fabric-data-engineering-capabilities`.

## Capabilities

### New Capabilities

- `powerbi/authoring-skill-migration`: Provide a cohesive, selectively merged Power BI authoring skill suite with clear ownership boundaries, local capability preservation, and multi-harness discovery.

### Modified Capabilities

- None.

## Impact

- Updates selected Power BI skill definitions, related agents, plugin/catalog metadata, and multi-harness projections.
- Uses the FIN-1810 Power BI merge plan as an input but makes its behavior and acceptance criteria explicit in OpenSpec.
- Depends on the separate FabricIQ and Fabric data-engineering changes for their specialized capability contracts.
