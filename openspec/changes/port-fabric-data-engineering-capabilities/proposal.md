## Why

The local Fabric plugin exposes only broad CLI guidance, while the upstream Fabric skills collection provides dedicated data-engineering orchestration and migration personas with specialized, progressively disclosed skills. FIN-1810 needs those capabilities available without importing unrelated Fabric personas or weakening the local Power BI work already in progress.

## What Changes

- Add `FabricDataEngineer` and `FabricMigrationEngineer` from the reference collection as the only new Fabric agent personas.
- Import the dependency closure required by those agents: Spark/Lakehouse, Warehouse SQL, Eventhouse, Eventstream, Dataflows, Medallion architecture, and Synapse, HDInsight, and Databricks migration skills, with only their necessary shared references.
- Integrate the separate FabricIQ consumption change as a required companion capability rather than duplicating its skill or MCP plan.
- Make the selected data-engineering agents and skills discoverable and usable in Codex, Claude Code, and GitHub Copilot CLI using the upstream repository's packaging and MCP patterns.
- Preserve the existing local Power BI skills and agents as their own workstream; apply only the already-approved, selective Power BI merge changes.
- Exclude `FabricAdmin`, `FabricAppDev`, the `FabricIQ` agent persona, ontology authoring, governance, and all other reference Fabric skills outside the two agents' dependency closure.

## Capabilities

### New Capabilities

- `fabric/data-engineering-orchestration`: Provide cross-workload Fabric data-engineering orchestration through the Data Engineer and Migration Engineer personas and their specialist skill dependencies.
- `fabric/multiharness-discovery`: Make the selected Fabric data-engineering capability available through Codex, Claude Code, and GitHub Copilot CLI without preloading unrelated guidance.

### Modified Capabilities

- None.

## Impact

- Adds selected upstream agents, skills, and shared reference material under `plugins/fabric`.
- Extends the local plugin manifest, marketplace/catalog metadata, MCP registration, installation workflow, and documentation for all three supported harnesses.
- Coordinates with `add-fabriciq-consumption-skill` for FabricIQ MCP configuration and consumption routing.
- Does not modify or remove unrelated local Fabric, Power BI, DevOps, skill-creator, or spec-lifecycle capabilities.
