## MODIFIED Requirements

### Requirement: The repository catalog is the shared content source
The repository SHALL retain `plugins/**`, its marketplace catalog, top-level agent Markdown files, checked-in Codex `.toml` adapters, and `.mcp.json` definitions as the source catalog for platform-neutral skills, references, scripts, templates, agent instructions, Codex agent metadata, and MCP server declarations. A Codex projection SHALL be traceable to those artifacts and SHALL add an adapter only where the installed Codex runtime requires host-specific discovery, role invocation, or MCP registration behavior.

#### Scenario: Complete plugin inventory is projected
- **WHEN** compatibility validation enumerates the marketplace catalog and plugin filesystem
- **THEN** every catalog plugin has a Codex-discoverable projection or an explicit runtime limitation, and no plugin is silently omitted

#### Scenario: A source artifact is directly usable
- **WHEN** a skill, reference, script, template, or agent instruction is already compatible with Codex discovery
- **THEN** the projection uses that source artifact without creating a separately maintained Codex rewrite of its domain guidance

### Requirement: Agents retain their specialist behavior in Codex
Codex-facing exposure of agents SHALL preserve each source agent's role, scope, required skills, safety constraints, workflow expectations, and tool-use intent, while translating only runtime-required discovery or invocation metadata.

#### Scenario: Power BI and DevOps agents are loaded
- **WHEN** a user invokes a Codex-exposed agent for a supported Power BI or DevOps task
- **THEN** Codex receives the source specialist instructions and referenced skills without requiring Copilot-specific invocation syntax

#### Scenario: Agent instructions reference repository assets
- **WHEN** an exposed agent refers to a skill, script, reference, or template
- **THEN** the reference resolves from the installed projection or is reported as a validation error before release

#### Scenario: Source agent is projected to Codex
- **WHEN** a supported agent is installed for Codex
- **THEN** Codex receives the checked-in `.toml` adapter and its source-preserving instruction payload without requiring installer-time Markdown conversion

### Requirement: MCP integrations remain source-derived and explicit
Codex compatibility SHALL derive Fabric and Power BI MCP registration from their declared `.mcp.json` definitions, preserving server names, commands, arguments, and tool exposure or documenting a Codex-equivalent configuration with the same capabilities.

#### Scenario: MCP configuration is installed
- **WHEN** a user installs the `fabric` or `powerbi` plugin for the Codex target
- **THEN** the corresponding source-derived MCP server configuration is available to Codex and setup identifies whether it was configured or skipped

#### Scenario: An existing same-name MCP server is encountered
- **WHEN** Codex configuration already contains a server with a managed Fabric or Power BI server name
- **THEN** setup identifies whether the entry is installer-owned and updates it safely, or reports an actionable conflict without overwriting an unknown user-owned entry

#### Scenario: MCP configuration cannot be activated
- **WHEN** the required runtime, package manager, or Codex configuration location is unavailable
- **THEN** setup reports a non-success status with actionable remediation and does not claim that the integration is ready

### Requirement: Existing host integrations remain compatible
Codex exposure SHALL be additive or isolated such that existing GitHub Copilot CLI, VS Code, and Claude plugin discovery and setup behavior continues to work with the same source plugins.

#### Scenario: Existing Copilot setup is run after Codex exposure is added
- **WHEN** the existing default Copilot setup and verification workflow is executed
- **THEN** it continues to install, register, and validate its targeted plugins without depending on Codex files

#### Scenario: Shared source content is updated
- **WHEN** a platform-neutral skill or reference is changed for compatibility
- **THEN** the change remains valid for the other supported hosts or has an explicit thin host-specific adapter rather than silently weakening their behavior

## ADDED Requirements

### Requirement: Codex agent adapters are packaged and traceable
Every packaged top-level agent Markdown file exposed to Codex SHALL have one corresponding checked-in `.toml` adapter under the same plugin's `agents/` directory. The adapter SHALL preserve the source agent's role, scope, required skills, safety constraints, workflow expectations, and instruction payload while adding only Codex-native metadata.

#### Scenario: Complete agent adapter inventory is validated
- **WHEN** compatibility validation enumerates plugin agent sources and Codex adapters
- **THEN** each supported agent Markdown file has exactly one matching `.toml`, every `.toml` maps to a source agent, and missing, stale, or orphaned pairs fail validation

#### Scenario: Codex adapter contents are reviewed
- **WHEN** a maintainer changes a source agent or its Codex adapter
- **THEN** the paired files are visible as version-controlled changes and validation reports any instruction or identity mismatch before release
