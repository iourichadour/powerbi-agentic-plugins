# TROUBLESHOOTING.md

Living log of investigated issues in this repo, written so an agent can resume
or reproduce an investigation without repeating discovery work from scratch.

## How to use this file

- One `##` section per Jira ticket or issue.
- Keep entries factual: symptom, data flow traced, root-cause candidates with
  file/line evidence, environment notes, and current status.
- Update the entry in place as new evidence is gathered instead of duplicating it.

## Standard troubleshooting environment

- Platform: Windows x64.
- MCP validation: `scripts\test-powerbi-modeling-mcp-smoke.ps1`.
- Live-query connection: not applicable; this incident concerns local MCP process
  startup and MCP `initialize`, not a data query.

## Reusable guidance

Keep only confirmed, reusable facts here. Ticket-specific symptoms, branches,
status, evidence, and next steps belong in the matching ticket section below.

### Environment and diagnostic patterns

- Record a known-good environment, connection, diagnostic shortcut, limitation,
  prevention rule, or remediation pattern only after it is supported by an
  investigation.
- Write entries so a cold-start agent can apply them without relying on a
  ticket, branch, or conversation transcript.

---

## FIN-1909

**Status:** Fixed in the active Copilot projection; restart Copilot CLI to reload
the MCP server definition.
**Branch:** `feature/FIN-1909-ai-skills-jira-workflow-skill-update`
**Jira:** https://bayviewassetmanagement.atlassian.net/browse/FIN-1909

### Symptom

Copilot failed to start `powerbi-modeling-mcp` with:
`failed to spawn MCP server process: failed to inspect suspended MCP server
36936: Access is denied. (os error 5)`.

### Data flow traced

`plugins\powerbi\.mcp.json` -> `setup-team-plugins.ps1` Windows projection ->
`%USERPROFILE%\.copilot\installed-plugins\powerbi-agentic-plugins\powerbi\.mcp.json`
-> Copilot local MCP process -> MCP `initialize`.

### Root-cause candidates

1. **Windows host process inspection does not reliably handle the `npx.cmd`
   batch shim.** The checked-in source is portable, while the prior Windows
   projection generated `npx.cmd` and the platform package. The package itself
   starts successfully outside Copilot, but the host reported access denied while
   inspecting its suspended launch process.
   Evidence: `setup-team-plugins.ps1` previously generated `npx.cmd`; direct
   `node.exe` invocation with npm `npx-cli.js` completed `initialize`.

2. **MCP package or network provisioning failure.** Ruled out: the pinned
   `@microsoft/powerbi-modeling-mcp-win32-x64@1.0.0` package is available and the
   standalone smoke test completed the MCP `initialize` exchange.

### Live-query evidence

- `scripts\test-powerbi-modeling-mcp-smoke.ps1` passed using direct
  `node.exe` + npm `npx-cli.js`.
- Setup completed with `MCP=ready: powerbi-modeling-mcp` after projecting the
  direct Node launcher.

### Current status

Root cause confirmed as the Windows `npx.cmd` launch path interacting badly with
the host's suspended-process inspection. The Windows projection now invokes
`node.exe` directly with npm's `npx-cli.js`; the source declaration remains
portable for non-Windows hosts.

### Actions taken this session

- Confirmed the stale failing definition was the manually added
  `powerbi-authoring-local` entry in `%USERPROFILE%\.copilot\mcp-config.json`.
- Removed that duplicate `npx`-based entry so only the repository-managed
  `powerbi-modeling-mcp` projection remains.
- Re-ran `setup-team-plugins.ps1 -Target Copilot -PluginName powerbi -Force`;
  the projection now uses `node.exe` and
  `@microsoft/powerbi-modeling-mcp-win32-x64@1.0.0`.
- Re-ran `scripts\test-powerbi-modeling-mcp-smoke.ps1`; MCP `initialize`
  succeeded.
- Updated Windows MCP projection and provisioning to use direct Node execution.
- Updated setup regression and smoke coverage.
- Reinstalled the active Copilot Power BI plugin projection.
- Restart Copilot CLI is required for the running session to discover the new
  process definition.

### Follow-up: legacy Codex registration and Windows TOML escaping

**Symptom:** `setup-team-plugins.ps1 -Target Codex -PluginName powerbi -Force`
reported that `powerbi-modeling-mcp` was not installer-owned, and a manually
repaired direct-Node registration required doubled backslashes in Windows paths.

**Root cause:** the existing Codex block was created by an older installer
version without ownership markers, and the generated TOML serializer emitted
single backslashes in `command` and `args` paths.

**Fix:** exact pinned legacy `npx` signatures are now migrated only by `-Force`
and receive ownership markers; unrelated user-owned collisions remain blocked.
Windows command and argument paths are escaped for TOML. The real Codex force
setup completed and MCP `initialize` passed.
