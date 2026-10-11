## 1. Dependency and source mapping

- [x] 1.1 Build a machine-readable dependency graph from `FabricDataEngineer.agent.md`, `FabricMigrationEngineer.agent.md`, and their selected skill references; verify every delegated skill and shared file has an approved disposition.
- [x] 1.2 Inventory the reachable `common/`, `references/`, `scripts/`, and `resources/` files for the selected skills; verify no unrelated upstream Fabric capability is included.
- [x] 1.3 Compare the selected upstream skills with local `fabric-cli` and existing Power BI semantic-model guidance; verify ownership boundaries and no duplicate semantic-model skill is introduced.

## 2. Data-engineering capability slice

- [x] 2.1 Port `spark-cli`, `sqldw-cli`, `eventhouse-cli`, `eventstream-cli`, `dataflows-cli`, and `e2e-medallion-architecture` with their reachable resources; verify each skill has valid routing metadata and only on-demand reference links.
- [x] 2.2 Port `synapse-migration`, `hdinsight-migration`, and `databricks-migration` with their reachable resources; verify each supports assessment and phased migration without hardcoded identifiers or credentials.
- [x] 2.3 Add `FabricDataEngineer` and `FabricMigrationEngineer` as Fabric plugin agents; verify all delegation targets resolve to an installed skill or an explicitly guarded FabricIQ prerequisite.
- [x] 2.4 Refine `fabric-cli` routing and Fabric plugin documentation so broad operational tasks remain supported without competing with the new specialist skills; verify one clear owner per request category.

## 3. FabricIQ and Power BI coordination

- [ ] 3.1 Verify `add-fabriciq-consumption-skill` has completed its MCP contract and smoke-test gates before enabling any `fabriciq` delegation; verify unavailable FabricIQ routing returns an actionable message.
- [x] 3.2 Coordinate selected skills with the existing local semantic-model authoring capability and approved Power BI merge work; verify no duplicated skill directory or conflicting agent ownership is created.

## 4. Multi-harness projection and MCP registration

- [x] 4.1 Extend the source-to-projection catalog for the selected Fabric skills and agents; verify every selected source asset maps to Codex, Claude Code, and GitHub Copilot CLI without duplicated domain-content copies.
- [x] 4.2 Implement Codex projection and MCP configuration merging for the selected Fabric capability; verify skills, agents, and required MCP services are discoverable while unrelated user configuration is preserved.
- [x] 4.3 Implement Claude Code plugin/marketplace projection and MCP configuration merging; verify the selected skills and agents are discoverable and connection failures provide recovery guidance.
- [x] 4.4 Implement GitHub Copilot CLI marketplace/plugin projection and MCP configuration merging; verify the selected skills and agents are discoverable and existing Copilot configuration is preserved.

## 5. Verification and rollout

- [x] 5.1 Add automated catalog and reference-resolution tests for the selected dependency closure; verify excluded upstream personas and skills are not projected.
- [ ] 5.2 Run targeted routing tests for a Spark/Lakehouse workflow, Warehouse SQL task, Eventhouse task, Eventstream task, Dataflow task, Medallion design, and each supported migration source; verify only the relevant skill and references are selected.
- [ ] 5.3 Run installation and discovery checks for Codex, Claude Code, and GitHub Copilot CLI in isolated test profiles; verify MCP conflicts, authentication failures, and rollback paths are reported safely.
- [ ] 5.4 Update maintainer and user documentation with the selected capability scope, harness-specific installation and verification instructions, FabricIQ prerequisite, and rollback process; verify commands match the implemented installer.
