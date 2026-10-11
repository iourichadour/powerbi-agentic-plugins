## Why

The repository is currently documented and installed primarily as a GitHub Copilot/Claude plugin collection, while Codex needs its own skill, agent-instruction, MCP, and user-profile discovery conventions. Without an explicit Codex compatibility layer, team members cannot install the same Fabric, Power BI, DevOps, skill-creator, and spec-lifecycle capabilities consistently in Codex or verify that every plugin and agent is available.

## What Changes

- Add a Codex projection of all supported plugins and agents while retaining `plugins/**` as the repository source catalog for skills, references, scripts, templates, agent instructions, Codex adapters, and MCP definitions.
- Add a checked-in Codex `.toml` adapter beside every packaged top-level agent Markdown file, with the adapter's instructions kept in parity with the source agent.
- Define a consistent mapping from the existing repository plugins, skills, agents, checked-in Codex adapters, and MCP definitions to Codex discovery and configuration; setup must copy these artifacts rather than generate them.
- Remove installer-time Markdown-to-TOML conversion. Missing or stale checked-in adapters must be reported by validation instead of being synthesized during setup.
- Extend `setup-team-plugins.ps1` with a `-Target Codex|Copilot|All` selector. When `-Target` is omitted, default to `All` and run isolated Codex and Copilot installations from the shared source catalog.
- Make the target-selecting setup workflow support all plugins or a selected plugin, repository-path discovery, force/reinstall behavior, backups, prerequisite validation, MCP configuration, and post-install verification for each selected harness.
- Add only the Codex-specific discovery, invocation, path, tool, or sub-agent metadata needed to expose existing agent instructions; retain platform-neutral domain guidance without a second independently authored domain implementation.
- Update README, developer setup, team deployment, plugin, and agent instructions with target-specific installation, verification, troubleshooting, and update instructions, including the commands an agent uses when a user asks it to install one or both harnesses.
- Add validation/tests that enumerate every plugin and agent, confirm the Codex projection is complete and traceable to the source catalog, and do not regress the Copilot installer.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `codex-plugin-compatibility`: Require checked-in Codex agent adapters, source-to-adapter parity validation, and deterministic Codex projection.
- `codex-team-setup`: Require setup to consume prebuilt Codex agent adapters rather than generating them during installation.

## Impact

- Repository plugin manifests and content under `plugins/`, including checked-in Codex agent adapters paired with their source agent Markdown files.
- Codex-facing repository metadata/instructions such as `AGENTS.md` and any new Codex configuration or skill locations.
- A revised target-selecting PowerShell setup script and installation tests; the script consumes checked-in `.toml` adapters and no longer owns their conversion or authoring.
- User-profile installation locations and MCP registration used by Codex; installed assets are projections of the source catalog, and the exact paths and supported configuration shape must be confirmed against the installed Codex runtime during implementation.
- Team-facing documentation, agent-guided installation instructions, and verification commands.
- Existing Copilot, Claude, and VS Code installation paths remain supported and should not be overwritten or made dependent on Codex.
