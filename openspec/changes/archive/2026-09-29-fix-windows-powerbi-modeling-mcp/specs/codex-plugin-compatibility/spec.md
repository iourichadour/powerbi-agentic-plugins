## MODIFIED Requirements

### Requirement: MCP integrations remain source-derived and explicit
Harness compatibility SHALL derive Fabric and Power BI MCP registration from their declared `.mcp.json` definitions, preserving server names, tool exposure, and equivalent capabilities. When a source declaration requires a host-specific launch adaptation, each harness projection SHALL apply that adaptation explicitly and SHALL report the resolved command and arguments used for the target host.

`powerbi-modeling-mcp` SHALL be the canonical server identity. `powerbi-modeling` SHALL be treated as a legacy alias for migration and conflict detection. Same-name definitions SHALL be compared by transport and launch signature, including URL or command, arguments, and non-secret headers; a hosted HTTP definition SHALL NOT be treated as equivalent to a local stdio definition or silently overwritten when it is not installer-owned.

#### Scenario: MCP configuration is installed
- **WHEN** a user installs the `fabric` or `powerbi` plugin for the Codex target
- **THEN** the corresponding source-derived MCP server configuration is available to Codex and setup identifies whether it was configured or skipped

#### Scenario: Windows Power BI Modeling MCP configuration is installed
- **WHEN** setup installs or registers the Power BI Modeling MCP on Windows for Codex or Copilot
- **THEN** the harness receives a launch command that avoids the package's broken runtime `npm` auto-install path while preserving the Power BI Modeling MCP capability

#### Scenario: Windows architecture is unsupported
- **WHEN** setup targets Windows with an architecture other than x64
- **THEN** setup fails the Power BI Modeling MCP capability before writing a Windows x64 projection and reports the supported architecture and remediation

#### Scenario: An existing same-name MCP server is encountered
- **WHEN** Codex configuration already contains a server with a managed Fabric or Power BI server name
- **THEN** setup identifies whether the entry is installer-owned and updates it safely, or reports an actionable conflict without overwriting an unknown user-owned entry

#### Scenario: Copilot profile MCP mirrors contain a same-name server
- **WHEN** Copilot profile files contain `powerbi-modeling-mcp` in either `mcp.json` using `servers` or `mcp-config.json` using `mcpServers`
- **THEN** setup evaluates both definitions together, identifies stale or conflicting commands, and does not silently overwrite an unowned profile entry

#### Scenario: Same-name hosted and local definitions coexist
- **WHEN** a profile contains a hosted HTTP `powerbi-modeling-mcp` definition and setup would register the local Windows stdio definition
- **THEN** setup compares the transport and endpoint signatures, reports the definitions as distinct same-name registrations, and preserves the unowned hosted definition

#### Scenario: MCP configuration cannot be activated
- **WHEN** the required runtime, package manager, or Codex configuration location is unavailable
- **THEN** setup reports a non-success status with actionable remediation and does not claim that the integration is ready
