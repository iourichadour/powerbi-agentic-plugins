## 1. MCP integration and capability contract

- [x] 1.1 Add the supplied `FabricIQ` HTTP server entry to `plugins/fabric/.mcp.json` alongside `fabric-mcp-server`, and verify the JSON retains both server definitions.
- [x] 1.2 Install or refresh the Fabric plugin for the Codex target and verify the FabricIQ server connects without authentication or transport errors.
- [x] 1.3 Discover the connected FabricIQ tools through `tools/list`, document the exact local mappings for artifact discovery, artifact resolution, report metadata, semantic-model schema, value search, and DAX query execution, and verify every required operation is available.
- [x] 1.4 Run a read-only smoke test against an authorized Power BI report or semantic model and verify the returned metadata and query result are accessible to the configured tenant.

## 2. FabricIQ consumption skill

- [x] 2.1 Add `plugins/fabric/skills/fabriciq/SKILL.md` with valid semver metadata and verify the skill validator accepts its frontmatter.
- [x] 2.2 Port the latest reference `plugins/fabric-skills/skills/fabriciq` workflow as an additive local capability, adapting only the discovered local tool names, response shapes, and unavailable documentation links; verify it covers artifact resolution, schema inspection, value lookup, bounded DAX queries, and source-bound answers.
- [x] 2.3 Add governance rules for verified-answer priority, custom-instruction compliance, report-filter preservation, explicit filter overrides, and unsupported-artifact handling; verify each behavior against the OpenSpec scenarios.
- [x] 2.4 Add local-only routing and error guidance in place of unavailable reference `COMMON-CORE.md` and `COMMON-CLI.md` links, and verify the skill contains no broken relative references.

## 3. Plugin and companion-skill routing

- [x] 3.1 Update the Fabric plugin README and installation/discovery documentation to identify FabricIQ as the route for natural-language report and semantic-model data questions, and verify the scope remains distinct from `fabric-cli` operations.
- [x] 3.2 Update `powerbi-report-management` to route business questions over report data to `fabriciq` only after the MCP smoke test and skill validation pass, and verify report CRUD behavior remains unchanged.
- [x] 3.3 Update `semantic-model-authoring` to route business questions to `fabriciq` while retaining semantic-model edits and user-supplied DAX in its own scope, and verify the boundary with a routing review.

## 4. End-to-end verification

- [x] 4.1 Validate the Fabric plugin catalog and Codex installation path, and verify the installed `fabriciq` skill and FabricIQ MCP server are discoverable.
- [x] 4.2 Exercise the OpenSpec scenarios using an authorized report and semantic model: report discovery, verified-answer use, explicit filter override, unsupported artifact handling, and unavailable-capability handling.
- [x] 4.3 Review the final configuration for tenant-specific URLs, credentials, and accidental secret material, and verify rollback consists of removing the FabricIQ server entry and companion routing redirects.
