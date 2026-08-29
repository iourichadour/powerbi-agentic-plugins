# Make all plugins Claude Code–compatible + add a Claude Code setup script

## Context

`powerbi-agentic-plugins` ships four plugins (`powerbi`, `fabric`, `devops`,
`skill-creator`) and today is installed **only** for GitHub Copilot CLI / VS Code
via `setup-team-plugins.ps1` (which copies into `~/.copilot/...`). The README
claims the repo is "Built for GitHub Copilot CLI and Claude Code", and a valid
`.claude-plugin/marketplace.json` already exists — but Claude Code support is only
half-wired:

- Only `skill-creator` has a per-plugin `.claude-plugin/plugin.json`; `powerbi`,
  `fabric`, `devops` have none, so `claude plugin install <name>@…` cannot resolve
  them from the marketplace.
- The three persona agents (`powerbi-architect.agent.md`,
  `powerbi-developer.agent.md`, `devops.agent.md`) use Copilot-only frontmatter:
  no `name:` field, `tools:` values that are not Claude Code tool names
  (`vscode`, `execute`, `search`, `todo`, …), and `model: Claude Sonnet 5 (copilot)`
  style strings that Claude Code does not accept.
- `plugins/powerbi/.mcp.json` uses `"type": "local"` (Copilot spelling) instead of
  the MCP-standard `"stdio"`.
- There is no script or documented path to install these plugins into Claude Code.

Goal: every plugin loads cleanly in Claude Code (skills + agents + MCP), the
Copilot/VS Code path keeps working, and a new `setup-claude-plugins.ps1` installs
them through the supported `claude plugin` marketplace commands.

Skills need **no changes** — all `SKILL.md` files already use valid
`name:` + `description:` Anthropic frontmatter.

## Changes

### 1. Add per-plugin `.claude-plugin/plugin.json` (3 new files)

Create for `powerbi`, `fabric`, `devops`, mirroring `skill-creator`'s file and the
metadata already in `.claude-plugin/marketplace.json`:

- `plugins/powerbi/.claude-plugin/plugin.json` — name `powerbi`, version `0.3.0`
- `plugins/fabric/.claude-plugin/plugin.json` — name `fabric`, version `0.2.0`
- `plugins/devops/.claude-plugin/plugin.json` — name `devops`, version `0.1.0`

Each: `{ name, description (from marketplace.json), version, author, keywords }`.
Also add `"version": "1.0.0"` to `plugins/skill-creator/.claude-plugin/plugin.json`
(currently missing) so all four report a version.

Leave default component discovery (`skills/`, `agents/`, `.mcp.json`) — no path
overrides needed once agent files are normalized (step 2).

### 2. Normalize the persona agent files

Rename to plain `.md` (Claude Code derives nothing useful from the `.agent.md`
double extension) and fix frontmatter to be valid for Claude Code while staying
readable by Copilot:

| From | To |
|---|---|
| `plugins/powerbi/agents/powerbi-architect.agent.md` | `powerbi-architect.md` |
| `plugins/powerbi/agents/powerbi-developer.agent.md` | `powerbi-developer.md` |
| `plugins/devops/agents/devops.agent.md` | `devops.md` |

`plugins/powerbi/agents/pbip-validator.md` is already Claude-style — only change
its `model:` value (see below).

Frontmatter normalization for all four agents:
- Add `name:` where missing (`powerbi-architect`, `powerbi-developer`).
- `model:` → Claude Code values: `Claude Sonnet 5 (copilot)` → `sonnet`;
  `Claude Haiku 4.5 (copilot)` → `haiku`; `Claude Sonnet 4.6 (copilot)` → `sonnet`.
- `tools:` → replace Copilot names with Claude Code tools. Map:
  `read`→`Read`, `edit`→`Edit`, `execute`→`Bash`, `search`→`Grep, Glob`,
  `web`→`WebFetch, WebSearch`, `agent`→`Task`; drop `vscode`, `todo`, `browser`.
  Keep MCP access by listing the server prefix (e.g. `mcp__powerbi-modeling-mcp`)
  instead of `powerbi-modeling-mcp/*`. For `powerbi-architect` (read/design only)
  keep it tight: `Read, Grep, Glob, WebFetch, Write, Edit`.
- Keep all prose/body content unchanged.

Update references to the old filenames: `README.md`, `plugins/powerbi/README.md`,
`plugins/devops/README.md`, `CONTRIBUTING_TEAM.md`, `CLAUDE.md`, `AGENTS.md`
(grep for `agent.md`).

### 3. Normalize `.mcp.json`

- `plugins/powerbi/.mcp.json`: `"type": "local"` → `"type": "stdio"`.
- `plugins/fabric/.mcp.json`: already fine (no `type` = stdio); optionally add
  `"type": "stdio"` for parity.
- The non-standard `"tools": ["*"]` key inside each server entry is ignored by
  Claude Code — leave it (Copilot reads it) or drop it; low stakes.

When a plugin is installed through the `claude plugin` system its `.mcp.json`
servers are registered automatically as plugin-scoped MCP servers, so the setup
script does **not** need to touch MCP config.

### 4. New `setup-claude-plugins.ps1` (repo root)

Standalone PowerShell script, same house style / helper-function shape as
`setup-team-plugins.ps1` (reuse `Write-Header/Success/Info`, `Find-Repository`,
`Get-MarketplaceName` patterns — copy, don't import). It drives the supported
`claude` CLI marketplace commands rather than copying files.

Parameters:
- `-RepositoryPath <path>` — local clone; else auto-detect (`$PSScriptRoot`, then
  the same common locations `setup-team-plugins.ps1` searches).
- `-PluginName powerbi|fabric|devops|skill-creator` — install one; default: all.
- `-Force` — reinstall even if already present (`--force` on install, or
  uninstall+install).
- `-Uninstall` — remove the plugins (and offer to remove the marketplace).
- `-SkipDesktopBridge` — skip the npm global install.
- `-Verbose`.

Flow:
1. Process-scoped `Set-ExecutionPolicy Bypass`.
2. Prereqs: PowerShell 5.1+, `claude` on PATH (`Get-Command claude`; hard-fail
   with install hint if missing), `git`, `node`/`npm` (warn only).
3. Resolve repo path; read `.claude-plugin/marketplace.json` for the marketplace
   `name` (`powerbi-agentic-plugins`) and the plugin→version list.
4. Register / refresh the marketplace from the local clone:
   - `claude plugin marketplace add "<repoPath>"`
   - if it already exists → `claude plugin marketplace update powerbi-agentic-plugins`
   - tolerate the "already exists" error and continue.
5. For each target plugin: `claude plugin install <name>@powerbi-agentic-plugins`
   (add `--force` when `-Force`). Capture output; on a trust/interactive prompt,
   print the exact manual command and continue rather than hang.
6. If `powerbi` is in scope and not `-SkipDesktopBridge`:
   `npm install -g @microsoft/powerbi-desktop-bridge-cli` (lift the
   `Install-DesktopBridgeCli` function from `setup-team-plugins.ps1` verbatim).
7. Verify: `claude plugin list` and check
   `~/.claude/plugins/marketplaces/powerbi-agentic-plugins` /
   `~/.claude/plugins/repos/...`; print which plugins/skills/agents were picked up.
8. `-Uninstall` path: `claude plugin uninstall <name>@powerbi-agentic-plugins` per
   plugin, then prompt for `claude plugin marketplace remove powerbi-agentic-plugins`.
9. Next-steps banner: restart Claude Code / run `/plugin`, `git pull` +
   `claude plugin marketplace update` + `setup-claude-plugins.ps1 -Force` to update.

### 5. Documentation

- `README.md` — add a "Claude Code Setup" subsection under Getting Started
  (clone → `.\setup-claude-plugins.ps1` → `claude plugin list`), and correct the
  "every plugin follows the same structure" note now that it's actually true.
- `DEVELOPER_SETUP.md` — add the Claude Code quick-start alongside the Copilot one.
- `CONTRIBUTING_TEAM.md` — mention `setup-claude-plugins.ps1 -Force` as the
  Claude Code local-test loop; update `*.agent.md` → `*.md` references.
- Optionally bump `.claude-plugin/marketplace.json` `metadata.version`
  `0.3.0` → `0.4.0` (adds first-class Claude Code support).

Out of scope (pre-existing tech debt, not Claude-compat): the `check-updates`
skill / `AGENTS.md` both reference a root `package.json` that doesn't exist;
`prep-powerbi-for-report-copilot/install-skill.ps1` points at an external repo.
Note them, leave them.

## Files

**New:**
- `plugins/powerbi/.claude-plugin/plugin.json`
- `plugins/fabric/.claude-plugin/plugin.json`
- `plugins/devops/.claude-plugin/plugin.json`
- `setup-claude-plugins.ps1`

**Renamed + edited:**
- `plugins/powerbi/agents/powerbi-architect.agent.md` → `powerbi-architect.md`
- `plugins/powerbi/agents/powerbi-developer.agent.md` → `powerbi-developer.md`
- `plugins/devops/agents/devops.agent.md` → `devops.md`

**Edited:**
- `plugins/powerbi/agents/pbip-validator.md` (`model:` only)
- `plugins/powerbi/.mcp.json`, `plugins/fabric/.mcp.json`
- `plugins/skill-creator/.claude-plugin/plugin.json` (add `version`)
- `README.md`, `DEVELOPER_SETUP.md`, `CONTRIBUTING_TEAM.md`, `CLAUDE.md`,
  `AGENTS.md`, `plugins/powerbi/README.md`, `plugins/devops/README.md`
- `.claude-plugin/marketplace.json` (optional version bump)

## Verification

1. **Schema sanity** — `claude plugin validate` (if available) or manually
   confirm each `plugin.json` parses and has `name`.
2. **Fresh install** on this machine:
   ```powershell
   .\setup-claude-plugins.ps1 -RepositoryPath "C:\Development\powerbi-agentic-plugins" -Force
   claude plugin list          # powerbi, fabric, devops, skill-creator present
   ```
3. **In a Claude Code session** with the marketplace installed:
   - `/plugin` shows all four enabled.
   - Skills list includes e.g. `semantic-model-authoring`, `fabric-cli`,
     `git-branch-guard`, `skill-creator`.
   - Agents list includes `powerbi-architect`, `powerbi-developer`,
     `pbip-validator`, `devops` with correct model/tools (no load warnings in
     `claude --debug`).
   - `powerbi` plugin's `powerbi-modeling-mcp` server appears in `/mcp`.
4. **Single-plugin path** — `.\setup-claude-plugins.ps1 -PluginName devops`
   installs only `devops`.
5. **Uninstall path** — `.\setup-claude-plugins.ps1 -Uninstall` removes them and
   `claude plugin list` no longer shows the marketplace plugins.
6. **Regression** — `.\setup-team-plugins.ps1 -Force` still succeeds and
   `copilot /plugin list` is unchanged (agent rename + frontmatter edits didn't
   break Copilot discovery).

## Implementation summary (done)

Landed on branch `feature/claude-code-setup` (commit `73939b2`).

**Done as planned:**
- `plugins/{powerbi,fabric,devops}/.claude-plugin/plugin.json` added (name,
  description, version, author, keywords); `skill-creator/.claude-plugin/plugin.json`
  got `"version": "1.0.0"`.
- Persona agents renamed `*.agent.md` → `*.md` (`powerbi-architect`,
  `powerbi-developer`, `devops`) with Claude Code frontmatter: `name:` added,
  `tools:` mapped to real tool names, `model:` → `sonnet` / `haiku`.
  `pbip-validator.md` `model:` → `haiku`.
- `plugins/powerbi/.mcp.json` `type: "local"` → `"stdio"`; `plugins/fabric/.mcp.json`
  got `"type": "stdio"` for parity.
- `setup-claude-plugins.ps1` created at repo root — `-RepositoryPath`,
  `-PluginName`, `-Force`, `-Uninstall`, `-SkipDesktopBridge`, `-Verbose`.
- Docs: Claude Code sections in `README.md` and `DEVELOPER_SETUP.md`;
  `CONTRIBUTING_TEAM.md` agent-path + local-test-loop updates; structure block in
  `README.md` corrected. `marketplace.json` `metadata.version` `0.3.0` → `0.4.0`.

**Deviations from the plan:**
- `claude plugin install` has **no `--force` flag** (CLI is `install <plugin>`
  with `-y`, `-s/--scope`). `-Force` is implemented as uninstall-then-install;
  the script always passes `-y` for non-interactive runs.
- `marketplace add` is idempotent (exits 0 whether new or "already on disk"), so
  `Register-Marketplace` always runs `marketplace update <name>` afterward to
  refresh from source rather than branching on an "already exists" error.
- `powerbi-developer` was given `Write` in addition to `Edit` (plan's tool map
  omitted it) — an implementation agent needs to create files, matching the
  plan's own choice to grant `Write` to `powerbi-architect`.
- `devops` MCP prefixes written as `mcp__atlassian-rovo-mcp` and
  `mcp__atlassian-mcp-server` (the `com.atlassian/...` server name isn't a valid
  MCP tool-prefix token).
- Bonus: `tools/validate-skills.ps1` updated to discover `agents/*.md` (top-level
  plugin agents only), not just legacy `*.agent.md`, so the rename didn't blind
  the validator; reports regenerated.
- `AGENTS.md` needed no change (no `*.agent.md` references); `CLAUDE.md` likewise
  (its agent mention carries no file extension).

**Verified on this machine (2026-08-29):**
- `claude plugin validate` passes for `marketplace.json` and all four
  `plugin.json` files.
- `.\setup-claude-plugins.ps1 -Force` registers the marketplace, reinstalls all
  four plugins, and they show `enabled` in `claude plugin list`.
- `claude plugin details powerbi@…` lists 11 skills + 3 agents (`pbip-validator`,
  `powerbi-architect`, `powerbi-developer`) + the `powerbi-modeling-mcp` server;
  `devops@…` lists 3 skills + the `devops` agent.
- `tools/validate-skills.ps1` → 20/20 valid, 0 warnings.

**Not yet verified (needs a fresh Claude Code session / other env):**
- `/plugin` and `/mcp` panes in an interactive session; `claude --debug` load
  warnings.
- `-Uninstall` round-trip and the single-plugin `-PluginName` path end-to-end.
- Copilot regression (`.\setup-team-plugins.ps1 -Force` + `copilot /plugin list`).
