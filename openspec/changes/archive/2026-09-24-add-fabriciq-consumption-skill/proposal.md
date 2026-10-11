## Why

The updated report-management and semantic-model-authoring guidance routes business questions over report data to `fabriciq`, but this repository does not currently provide that capability. Adding a local FabricIQ consumption skill will give Codex a governed, source-bound route for answering natural-language questions against existing Power BI reports and semantic models.

## What Changes

- Add the current FabricIQ consumption skill from the reference `fabric-skills` plugin as an additive capability in the local Fabric plugin, for discovering reports and semantic models, inspecting their metadata, resolving user-supplied values, and querying model data.
- Add and validate the required FabricIQ MCP configuration and tool contract before the skill can be enabled.
- Define safety and correctness rules: respect model custom instructions and verified answers, preserve applicable report filters, resolve entity values before filtering, and never invent data.
- Wire compatible Power BI skills to route business-data questions to FabricIQ only when the capability is installed and available.
- Keep report-definition CRUD, PBIR authoring, semantic-model editing, and FabricIQ ontology authoring outside this skill's scope.

## Capabilities

### New Capabilities

- `powerbi/fabriciq-consumption`: Answer natural-language business questions from existing Power BI reports and semantic models through a configured FabricIQ MCP endpoint.

### Modified Capabilities

- None.

## Impact

- Adds a source-aligned FabricIQ skill under the Fabric plugin and updates its installation/discovery documentation.
- Requires a confirmed FabricIQ MCP endpoint exposing artifact discovery, report metadata, semantic-model schema, value-search, and DAX-query operations.
- May update the routing language in `powerbi-report-management` and `semantic-model-authoring` after the new capability is verified.
- Does not implement or import `fabriciq-ontology-cli`; ontology authoring remains a separate concern.
