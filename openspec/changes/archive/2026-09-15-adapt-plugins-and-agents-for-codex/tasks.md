## 1. Establish the shared catalog and Codex compatibility contract

- [x] 1.1 Inspect the installed Codex runtime's supported skill discovery, instruction, role-exposure, and MCP configuration conventions; record the resolved paths/schema and verify the target against the runtime or a documented local fixture
- [x] 1.2 Inventory `.claude-plugin/marketplace.json`, every `plugins/*` root, all `skills/**/SKILL.md`, all top-level plugin agents, and all `.mcp.json` files; add machine-checkable source-to-projection catalog validation that fails on missing, unadapted, or undeclared adapter entries
- [x] 1.3 Define the target-specific projection layout, ownership markers, same-name MCP conflict policy, and non-force behavior; verify neither target overlaps the other target's configuration or unrelated user assets

## 2. Preserve and expose shared plugin artifacts

- [x] 2.1 Implement source-preserving Codex exposure for the `powerbi` plugin and its agents; verify every source skill, reference, script, and template resolves from the projection without a duplicated domain-content rewrite
- [x] 2.2 Implement source-preserving Codex exposure for the `fabric` plugin; verify `fabric-cli` and supporting assets are discoverable
- [x] 2.3 Implement source-preserving Codex exposure for the `devops` plugin and agents; verify branch, Jira, troubleshooting, and policy references resolve
- [x] 2.4 Implement source-preserving Codex exposure for `skill-creator`; verify its skill, nested agent assets, scripts, references, and evaluation resources remain usable
- [x] 2.5 Implement source-preserving Codex exposure for `spec-lifecycle`; verify the OpenSpec bridge skill and references remain discoverable
- [x] 2.6 Add only runtime-required agent discovery or invocation adapters; verify a parity/reference test preserves each role's source instructions, required skills, safety constraints, and workflow expectations

## 3. Implement the unified target-selecting setup workflow

- [x] 3.1 Extend `setup-team-plugins.ps1` with `-Target Codex|Copilot|All`, defaulting to `All`; verify it resolves the repository and shared catalog once, rejects invalid target/plugin selectors before writes, and preserves selective target modes
- [x] 3.2 Implement target-specific destination resolution and projection of selected shared assets; verify default `All`, `Codex`, `Copilot`, and single-plugin installs in isolated temporary user profiles
- [x] 3.3 Implement target-owned manifests, timestamped backup, non-force behavior, and force/reinstall behavior; verify unrelated user assets and the other target's files/configuration remain unchanged
- [x] 3.4 Register Fabric and Power BI MCP servers from their source `.mcp.json` definitions using each runtime's supported schema; verify server commands, arguments, names, tool exposure, unavailable-runtime outcomes, and safe same-name conflict handling
- [x] 3.5 Add capability- and target-scoped checks/provisioning for Node/npm, `uv`, Power BI Desktop Bridge, ADOMD.NET, VS Code's Python extension, and other selected-plugin dependencies; verify optional failures are warnings and required failures are actionable target errors
- [x] 3.6 Add unified post-install output with per-target paths, plugins, skills, agents, MCP status, backups, restart/discovery actions, update commands, and recovery paths; verify it never claims unavailable capabilities or a failed target are ready

## 4. Validate target behavior and compatibility

- [x] 4.1 Add static tests that enumerate all five plugins, every packaged agent, every skill, each MCP definition, and every source-to-projection mapping; verify no catalog item is omitted and all references resolve
- [x] 4.2 Add integration tests for default `All`, explicit `All`, `Codex`, `Copilot`, selected-plugin, force update, non-force rerun, invalid target/plugin, missing repository, backup/recovery, missing optional dependency, and MCP conflict/failure cases; verify exit codes and filesystem/configuration effects
- [x] 4.3 Test an `All` run with an injected failure in one target; verify the successful target remains usable, the failed target provides a recovery path, and neither target mutates the other's configuration
- [x] 4.4 Run the existing Copilot/Claude/VS Code setup and validation checks; verify the explicit Copilot target remains compatible and Codex projection files do not alter existing host locations or registration
- [x] 4.5 Run the default all-target setup in a disposable user profile; verify Codex and Copilot discovery plus the complete MCP/tool inventory

## 5. Document direct and agent-guided setup

- [x] 5.1 Update `README.md` with default all-target setup, selective-target commands, prerequisites, verification, update, and recovery; verify commands match final script parameters
- [x] 5.2 Update `DEVELOPER_SETUP.md`, `TEAM_DEPLOYMENT_GUIDE.md`, and relevant plugin documentation with target-specific paths, MCP behavior, backups, troubleshooting, and recovery; verify no target's verification command is presented for the other target
- [x] 5.3 Update agent instructions to identify the requested harness before recommending or running setup, and to use the default or selective target commands accordingly; verify an unspecified user request prompts for Codex, Copilot, or both
- [x] 5.4 Add a compatibility/support matrix and maintainer guidance for adding plugins, agents, and host-specific adapters; verify each new catalog entry has a source-to-projection validation path
- [x] 5.5 Run OpenSpec validation and the full repository test/lint suite; verify every proposal requirement has an implementation, test, or documented limitation before marking the change complete
