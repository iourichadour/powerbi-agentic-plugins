## Purpose

Give team members and agents one safe, repeatable setup workflow for Codex, Copilot, or both harnesses from the shared plugin catalog.

## ADDED Requirements

### Requirement: Setup selects one or both harness targets
`setup-team-plugins.ps1` SHALL accept `-Target Codex`, `-Target Copilot`, or `-Target All`. When `-Target` is omitted, it SHALL default to `All`. The workflow SHALL process the shared source catalog once per run and report the selected target and plugin set before making changes.

#### Scenario: Codex-only installation
- **WHEN** a user runs setup with `-Target Codex`
- **THEN** only Codex-discoverable assets and Codex integration configuration for the selected plugins are installed for that user

#### Scenario: Copilot-only installation
- **WHEN** a user runs setup with `-Target Copilot`
- **THEN** the Copilot-compatible installation path is used without requiring Codex files or configuration

#### Scenario: Default or all-target installation
- **WHEN** a user omits `-Target` or runs setup with `-Target All`
- **THEN** setup performs one shared workflow that projects the catalog to both Codex and Copilot and reports a distinct result for each target

#### Scenario: Invalid target or plugin selector
- **WHEN** a user supplies an unsupported target or a plugin name outside the supported catalog
- **THEN** setup exits unsuccessfully before modifying either target and lists valid target and plugin names

### Requirement: Setup supports repeatable target-scoped updates and recovery
The setup workflow SHALL support explicit force/reinstall behavior, preserve recoverable backups of replaced target-owned files, and avoid deleting unrelated user configuration. It SHALL define and report its behavior when target-owned assets already exist without force.

#### Scenario: Updating an existing target installation
- **WHEN** a user reruns setup with force enabled for a target
- **THEN** only that target's installer-owned assets are replaced with the repository version, while unrelated assets and the other target's configuration remain unchanged

#### Scenario: One target fails during an All installation
- **WHEN** a Codex or Copilot operation fails during `-Target All`
- **THEN** setup identifies the failed target and location, provides its recovery path, and preserves the independently successful target's installation and backup

### Requirement: Setup resolves and validates the repository
The workflow SHALL accept an explicit repository path, discover a valid local checkout when no path is supplied, validate that the checkout contains the expected plugin catalog, and fail clearly when neither is available.

#### Scenario: Explicit repository path
- **WHEN** the user provides a path to a valid checkout
- **THEN** setup uses that checkout and reports the resolved source path

#### Scenario: Repository cannot be found
- **WHEN** no valid checkout can be resolved
- **THEN** setup does not create a partial installation and reports how to provide or obtain the repository

### Requirement: Setup verifies target readiness
The workflow SHALL validate target-required runtime prerequisites, confirm that every selected plugin has its required projected assets, verify agent and skill references, and distinguish warnings from blocking failures per target.

#### Scenario: Successful target validation
- **WHEN** setup completes for a target and selected plugin set
- **THEN** it reports the installed destination, plugin list, skills, agents, MCP status, and the target-specific command or action needed to verify discovery

#### Scenario: Optional dependency is unavailable
- **WHEN** an optional dependency such as Node.js, `uv`, or a desktop bridge is unavailable
- **THEN** setup identifies the affected capability and remediation while only failing the relevant target installation if that dependency is required for its selected plugin contract

### Requirement: Documentation supports direct and agent-guided installation
Team documentation and agent instructions SHALL explain target selection, prerequisites, installation, update, verification, MCP behavior, backup/recovery, and the distinction between Codex and Copilot paths.

#### Scenario: New team member follows the guide
- **WHEN** a team member follows the documented quick start from a clean machine or checkout
- **THEN** the instructions provide enough information to install and verify Codex, Copilot, or both without using the other harness's verification commands

#### Scenario: A user asks an agent to install the collection
- **WHEN** a user asks an agent to install plugins or capabilities without naming a harness
- **THEN** the agent asks whether to target Codex, Copilot, or both before presenting or running the corresponding setup command
