## MODIFIED Requirements

### Requirement: Setup verifies target readiness
The workflow SHALL validate target-required runtime prerequisites, confirm that every selected plugin has its required projected assets, verify checked-in Codex agent adapters and skill references, validate that configured MCP launch commands are host-compatible for both Codex and Copilot projections, complete a bounded MCP `initialize` exchange before claiming local MCP readiness, and distinguish warnings from blocking failures per target.

#### Scenario: Successful target validation
- **WHEN** setup completes for a target and selected plugin set
- **THEN** it reports the installed destination, plugin list, skills, agents, MCP status, and the target-specific command or action needed to verify discovery

#### Scenario: MCP launch command is not activatable
- **WHEN** a selected plugin's MCP command cannot be launched or its required package cannot be resolved for either selected harness
- **THEN** setup identifies the affected harness and MCP server, reports actionable remediation, and does not claim that target is ready

#### Scenario: MCP process remains alive but initialization fails
- **WHEN** a configured MCP process starts but does not complete the bounded `initialize` exchange
- **THEN** setup reports the harness, server, transport, and initialization failure and does not claim MCP readiness

#### Scenario: Copilot profile configuration conflicts with the installed plugin
- **WHEN** `%USERPROFILE%\\.copilot\\mcp.json` or `%USERPROFILE%\\.copilot\\mcp-config.json` contains a same-name MCP entry that points outside the installed plugin or to an unavailable executable
- **THEN** setup reports the affected profile file, schema, server name, and remediation, and does not claim the Copilot MCP integration is ready

#### Scenario: Equivalent profile definitions are mirrored across schemas
- **WHEN** the same canonical server definition appears in both `mcp.json` under `servers` and `mcp-config.json` under `mcpServers`
- **THEN** setup reports one logical definition or conflict with both file locations and does not count the mirror as two independent servers

#### Scenario: Hosted profile definition uses the canonical name
- **WHEN** a profile contains an unowned hosted HTTP `powerbi-modeling-mcp` entry and setup would register a local Windows stdio entry
- **THEN** setup reports the transport mismatch and preserves the hosted entry instead of silently overwriting it

#### Scenario: Optional dependency is unavailable
- **WHEN** an optional dependency such as Node.js, `uv`, or a desktop bridge is unavailable
- **THEN** setup identifies the affected capability and remediation while only failing the relevant target installation if that dependency is required for its selected plugin contract
