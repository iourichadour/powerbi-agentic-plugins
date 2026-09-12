## Purpose

Defines the packaging, portability, and validation conventions every plugin in this
repository must satisfy so it can be installed and verified through the Claude Code
plugin marketplace tooling, independent of which repo location is currently ahead.

## Requirements

### Requirement: Per-plugin Claude Code manifest
Each plugin directory under `plugins/<plugin-name>/` SHALL contain a
`.claude-plugin/plugin.json` manifest describing its name, description, version,
author, and keywords, so it can be registered individually with the `claude plugin`
marketplace commands.

#### Scenario: New plugin added
- **WHEN** a new plugin directory is added under `plugins/`
- **THEN** it includes a `.claude-plugin/plugin.json` manifest with at least
  `name`, `description`, and `version` fields before it is considered installable

#### Scenario: Marketplace install picks up manifest fields
- **WHEN** `setup-claude-plugins.ps1` registers the repository marketplace and
  installs a plugin by name
- **THEN** the plugin's own `.claude-plugin/plugin.json` is used to resolve its
  metadata, independent of the root `.claude-plugin/marketplace.json` entry

### Requirement: Dual-dialect persona agent files
A plugin's top-level persona agent under `plugins/<plugin-name>/agents/` MAY be
published in two parallel dialects that are both kept up to date together, not
one replacing the other: a plain `<agent-name>.md` file using Claude Code
frontmatter (`name:`, Claude Code tool names, `model: sonnet`/`haiku`/etc.) and
a `<agent-name>.agent.md` file using Copilot/VS Code frontmatter (`tools:`
list of Copilot tool identifiers, `model: <Model Name> (copilot)`). Both files
SHALL carry equivalent orchestration/body content; a change to one's behavior
SHALL be mirrored in the other in the same edit.

#### Scenario: An agent's behavior is updated
- **WHEN** a persona agent's numbered orchestration or responsibilities change
  in `<agent-name>.md`
- **THEN** the corresponding `<agent-name>.agent.md` file is updated in the
  same change to keep both dialects' body content equivalent

#### Scenario: Skill/agent validation runs
- **WHEN** `tools/validate-skills.ps1` scans `plugins/**/agents/`
- **THEN** it validates both the plain `<agent-name>.md` (Claude Code style)
  and any `*.agent.md` (Copilot style) files as first-class, independently
  valid agent definitions, not as a legacy/superseded pair where one is
  expected to be deleted

### Requirement: Portable sibling scripts for Bash-based agent environments
Any PowerShell helper script referenced by a plugin's agent or skill instructions
that must also run in a Bash-based environment (e.g. Claude Code on a
non-Windows shell) SHALL have a `.sh` sibling script with equivalent behavior,
alongside the original `.ps1`, so environments that cannot invoke PowerShell
scripts directly can still run the equivalent logic natively.

#### Scenario: Agent instructs running a helper script under a Bash-based environment
- **WHEN** an agent's instructions reference a helper script (e.g.
  `check_git_branch_guard.ps1`) for use under a Bash-based agent environment
- **THEN** a `.sh` sibling script exists alongside it with equivalent
  behavior, and the agent instructions document invoking `check_git_branch_guard.ps1`
  directly under PowerShell (5.1+ or PowerShell 7) and `check_git_branch_guard.sh`
  directly under Bash

### Requirement: Marketplace install script
The repository SHALL provide a `setup-claude-plugins.ps1` script at the repo root
that validates prerequisites, registers (or refreshes) the repository's
`.claude-plugin/marketplace.json` as a local Claude Code marketplace, and installs
either all plugins or a single named plugin.

#### Scenario: Installing all plugins
- **WHEN** a user runs `setup-claude-plugins.ps1` with no plugin name argument
- **THEN** the script registers the marketplace and installs every plugin listed
  in `.claude-plugin/marketplace.json`

#### Scenario: Installing a single plugin
- **WHEN** a user runs `setup-claude-plugins.ps1` with a specific plugin name
- **THEN** the script installs only that plugin from the registered marketplace

### Requirement: Skill and agent frontmatter validation tooling
The repository SHALL provide a `tools/validate-skills.ps1` script that scans every
`plugins/**/skills/*/SKILL.md` and `plugins/**/agents/*.agent.md` (or equivalent
agent file), checks each for required YAML frontmatter fields and basic structural
correctness, and writes one Markdown report per file plus a summary index under
`tools/validation-reports/`.

#### Scenario: Running validation after adding a skill
- **WHEN** a contributor runs `tools/validate-skills.ps1` after adding or editing a
  skill or agent file
- **THEN** a per-file Markdown report, an updated `_summary.md`, and an updated
  `_summary.json` are written to `tools/validation-reports/`

#### Scenario: Missing required frontmatter field
- **WHEN** a `SKILL.md` or agent file is missing a required frontmatter field
- **THEN** the corresponding validation report flags it as failing, and the
  `_summary.md`/`_summary.json` reflect the failure count

### Requirement: Skill evaluation reports
The repository SHALL provide a `skill-eval-reports/run-skill-eval.ps1` script that
runs evaluation scenarios for skills that define an `evals/evals.json`, and writes
per-skill JSON and Markdown reports plus a `SUMMARY.md` under
`skill-eval-reports/reports/`.

#### Scenario: Running skill evals
- **WHEN** a contributor runs `skill-eval-reports/run-skill-eval.ps1`
- **THEN** each evaluated skill gets a `<plugin>__<skill>.json` and
  `<plugin>__<skill>.md` report under `skill-eval-reports/reports/`, and
  `skill-eval-reports/reports/SUMMARY.md` is updated to reflect the latest run

### Requirement: No machine-local or crash-artifact files tracked
The repository SHALL NOT track machine-local Claude Code permission caches (e.g.
`.claude/settings.local.json`) or process crash artifacts (e.g.
`bash.exe.stackdump`); these SHALL be removed if found and, where applicable,
excluded via `.gitignore`.

#### Scenario: Crash dump or local settings file found during a repo sync
- **WHEN** a repository reconciliation or sync encounters `bash.exe.stackdump` or
  `.claude/settings.local.json`
- **THEN** the file is deleted rather than copied to the other location or
  committed
