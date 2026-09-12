## Purpose

Keeps the repo-level and skill-level update-check instructions pointed at the version and repository metadata that actually exists in this repo (`powerbi-agentic-plugins`), so an agent following them reads a real file instead of a nonexistent one.

## ADDED Requirements

### Requirement: Update-check instructions reference this repo's actual manifest
`AGENTS.md`'s update-check note and `plugins/powerbi/skills/check-updates/SKILL.md` SHALL instruct the agent to read version information from `.claude-plugin/marketplace.json` (the repo-level `metadata.version` and/or the relevant plugin's `version` entry) in the `YuriChadour/powerbi-agentic-plugins` repository. Neither document SHALL instruct the agent to read a root `package.json`, a `.github/plugin/plugin.json`, or any other manifest path that does not exist in this repo.

#### Scenario: Agent follows AGENTS.md and finds the referenced file
- **WHEN** an agent runs the update check described in `AGENTS.md`
- **THEN** the file path it is told to read for the local version SHALL exist in this repository

#### Scenario: check-updates skill targets this repo's owner and manifest
- **WHEN** an agent runs the `check-updates` skill's Step 1-3 procedure (local version, repository owner/name, latest-release fetch) as written in `SKILL.md`
- **THEN** the manifest path and repository (`YuriChadour/powerbi-agentic-plugins`) it reads and fetches from SHALL match this repo's actual structure, not the `skills-for-fabric`/`microsoft/skills-for-fabric` layout

#### Scenario: No dangling references to the old manifest layout remain
- **WHEN** the update-check documents are reviewed after this change
- **THEN** they SHALL NOT mention a root `package.json`, `.github/plugin/plugin.json`, or `microsoft/skills-for-fabric` as this repo's manifest or repository
