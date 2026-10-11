## Purpose

Make the selected Fabric data-engineering capability consistently discoverable and usable in Codex, Claude Code, and GitHub Copilot CLI.

## ADDED Requirements

### Requirement: Selected Fabric capabilities are discoverable in every supported harness

The system SHALL make `FabricDataEngineer`, `FabricMigrationEngineer`, and every approved dependency skill discoverable in Codex, Claude Code, and GitHub Copilot CLI. Each harness SHALL consume the same source-owned domain guidance without requiring separately maintained copies of skill bodies.

#### Scenario: Codex discovery

- **WHEN** the Fabric capability is installed for Codex
- **THEN** Codex can discover the selected skills and agent instructions from its supported catalog and configuration locations

#### Scenario: Claude Code and Copilot discovery

- **WHEN** the Fabric capability is installed for Claude Code or GitHub Copilot CLI
- **THEN** that harness can discover the same selected skills and agent instructions through its supported plugin or marketplace mechanism

### Requirement: MCP configuration preserves existing services

The system SHALL register the MCP services needed by the selected capability using each harness's supported configuration model. It SHALL preserve unrelated existing MCP servers and user configuration, and it SHALL not register unavailable or unverified services as ready.

#### Scenario: Harness already has MCP configuration

- **WHEN** installation targets a harness with existing MCP servers
- **THEN** installation merges the selected Fabric entries without deleting or overwriting unrelated server definitions

#### Scenario: MCP connection cannot be established

- **WHEN** a required MCP server cannot authenticate or expose its required tools
- **THEN** the installation reports the capability as unavailable with a recovery action and does not claim the dependent skill is operational

### Requirement: Installation verifies progressive-disclosure integrity

The system SHALL verify that each selected skill has valid routing metadata, that referenced local resources resolve, and that harness projections do not cause unrelated skill bodies or shared references to load for a targeted request.

#### Scenario: Selected skill references a shared file

- **WHEN** a selected skill is installed in any supported harness
- **THEN** its required shared references resolve on demand from the same projected source package
