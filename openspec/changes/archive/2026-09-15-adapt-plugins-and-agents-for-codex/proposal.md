## Why

The repository is currently documented and installed primarily as a GitHub Copilot/Claude plugin collection, while Codex needs its own skill, agent-instruction, MCP, and user-profile discovery conventions. Without an explicit Codex compatibility layer, team members cannot install the same Fabric, Power BI, DevOps, skill-creator, and spec-lifecycle capabilities consistently in Codex or verify that every plugin and agent is available.

## What Changes

- Add a Codex projection of all supported plugins and agents while retaining `plugins/**` as the single source of truth for skills, references, scripts, templates, agent instructions, and MCP definitions.
- Define a consistent mapping from the existing repository plugins, skills, agents, and MCP definitions to Codex discovery and configuration, creating Codex-specific adapters only where the runtime requires them.
- Extend `setup-team-plugins.ps1` with a `-Target Codex|Copilot|All` selector. When `-Target` is omitted, default to `All` and run isolated Codex and Copilot installations from the shared source catalog.
- Make the target-selecting setup workflow support all plugins or a selected plugin, repository-path discovery, force/reinstall behavior, backups, prerequisite validation, MCP configuration, and post-install verification for each selected harness.
- Add only the Codex-specific discovery, invocation, path, tool, or sub-agent metadata needed to expose existing agent instructions; retain platform-neutral domain guidance without a second maintained copy.
- Update README, developer setup, team deployment, plugin, and agent instructions with target-specific installation, verification, troubleshooting, and update instructions, including the commands an agent uses when a user asks it to install one or both harnesses.
- Add validation/tests that enumerate every plugin and agent, confirm the Codex projection is complete and traceable to the source catalog, and do not regress the Copilot installer.

## Capabilities

### New Capabilities

- `codex-plugin-compatibility`: Make every repository plugin, skill, agent, and MCP integration consumable through Codex-native discovery and instruction conventions.
- `codex-team-setup`: Provide a repeatable per-user PowerShell setup and verification workflow for installing and updating the complete plugin collection in Codex.

### Modified Capabilities

- None.

## Impact

- Repository plugin manifests and content under `plugins/`, which remain the authoritative source for all Power BI, Fabric, DevOps, skill-creator, and spec-lifecycle assets.
- Codex-facing repository metadata/instructions such as `AGENTS.md` and any new Codex configuration or skill locations.
- A revised target-selecting PowerShell setup script and installation tests.
- User-profile installation locations and MCP registration used by Codex; installed assets are projections of the source catalog, and the exact paths and supported configuration shape must be confirmed against the installed Codex runtime during implementation.
- Team-facing documentation, agent-guided installation instructions, and verification commands.
- Existing Copilot, Claude, and VS Code installation paths remain supported and should not be overwritten or made dependent on Codex.
