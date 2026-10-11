## ADDED Requirements

### Requirement: Agent Markdown files parse in Claude Code
Every plain `<agent-name>.md` agent file under `plugins/<plugin-name>/agents/` SHALL begin with its YAML frontmatter at byte 0, with no UTF-8 byte order mark or other leading bytes, so Claude Code can parse the frontmatter and list the agent.

#### Scenario: Agent file with a byte order mark
- **WHEN** an agent `.md` file starts with a UTF-8 byte order mark (`EF BB BF`) before the opening `---`
- **THEN** validation fails and names the file, and the file is not considered a valid Claude Code agent definition

#### Scenario: Agent file without a byte order mark
- **WHEN** an agent `.md` file's first three bytes are the opening `---` of its frontmatter
- **THEN** validation passes for that check

### Requirement: Validation reports agent parse problems before install
`tools/validate-skills.ps1` SHALL check agent Markdown files for the leading-byte rule above, in addition to its existing frontmatter checks, so a file that Claude Code cannot load is reported by the repo tooling instead of being discovered after install.

#### Scenario: Validator runs over all plugins
- **WHEN** `tools/validate-skills.ps1` scans `plugins/**/agents/`
- **THEN** every agent Markdown file with a byte order mark is listed as a failure with its path

### Requirement: Claude-format agents for plugins that ship to Claude Code
When a plugin's persona agent is published for Claude Code, it SHALL have a plain `<agent-name>.md` file alongside its `.agent.md` and `.toml` files, with equivalent body content and the one-to-one `.toml` pairing required by `codex-plugin-compatibility`.

#### Scenario: Fabric agent gains a Claude-format file
- **WHEN** a Claude-format `.md` is added for a Fabric agent that already has `.agent.md` and `.toml`
- **THEN** the three files keep equivalent body content and no orphaned or missing `.toml` pair is introduced

#### Scenario: Plugin agent deliberately left Claude-format-free
- **WHEN** a plugin's agent is intentionally not shipped for Claude Code
- **THEN** the omission is recorded in the plugin documentation instead of left implicit
