## Why

This repository currently supports interactive Power BI report authoring in PBIR/PBIP, but it has no dedicated workflow for creating, parameterizing, validating, and publishing paginated reports in RDL. PR #65 from `microsoft/skills-for-fabric` provides a focused starting point for semantic-model-bound paginated reports; integrating it into the Power BI plugin will make that capability discoverable and usable with this repository's plugin layout and agent routing.

## What Changes

- Add a `paginated-report-authoring` Power BI skill adapted from PR #65, including RDL structure, semantic-model connection strings, DAX datasets, parameters and filters, layout, publishing, troubleshooting, and reproducible script templates.
- Add the PR's RDL generator and publishing scripts under the new skill, adapting paths, frontmatter, authentication guidance, and repository conventions as needed.
- Route paginated-report requests from the `powerbi-developer` agent to the new skill while keeping PBIR/PBIP interactive report authoring routed to `powerbi-report-authoring`.
- Document the new capability in the Power BI plugin README and relevant trigger/integration metadata.
- Add offline validation and focused tests for the generator, XML well-formedness, script behavior, and skill discoverability; use live Fabric publishing only as an optional integration check.
- Preserve existing PBIR/PBIP and report-management responsibilities; no breaking changes to those skills are intended.

## Capabilities

### New Capabilities

- `powerbi/paginated-report-authoring`: Create and publish RDL paginated reports bound to Power BI semantic models, including DAX-backed datasets, report parameters, grouped tablix layouts, validation, and reliable upload workflows.

### Modified Capabilities

- None. Existing interactive report and agent requirements do not change; this proposal adds a separate report artifact workflow.

## Impact

- Affected areas: `plugins/powerbi/skills`, `plugins/powerbi/agents/powerbi-developer.agent.md`, `plugins/powerbi/README.md`, root documentation/metadata where plugin capabilities are enumerated, and tests.
- Source material: `microsoft/skills-for-fabric` PR #65, fetched from the user-provided local clone at `C:\Development\skills-for-fabric`.
- Runtime dependencies: Azure CLI for Fabric discovery/token acquisition, Python for RDL generation and XML validation, PowerShell 7+ for multipart upload, and `jq` where used by discovery examples. Secrets remain supplied by Azure CLI/environment authentication and must not be embedded or logged.
- External systems: Fabric workspace and semantic-model discovery APIs plus the Power BI Imports API; publishing requires a suitable Fabric/Premium/Embedded capacity and an authorized caller.
