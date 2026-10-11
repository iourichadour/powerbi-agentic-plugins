# Harness compatibility and maintainer guide

The repository catalog under `plugins/` is authoritative. The setup script projects it to independent host locations:

| Harness | Skills | Agents | MCP | Ownership / recovery |
|---|---|---|---|---|
| Codex | `%USERPROFILE%\.codex\skills` | Checked-in `%USERPROFILE%\.codex\agents\*.toml` adapters | `%USERPROFILE%\.codex\config.toml` | `.codex\powerbi-agentic-plugins.manifest.json`; backups in `.codex\backups` |
| Copilot | `%USERPROFILE%\.copilot\installed-plugins` and `.copilot\extensions` | Source agent files in the plugin projection | Source `.mcp.json` retained by Copilot | `.copilot\powerbi-agentic-plugins.manifest.json`; backups in `.copilot\backups` |

Codex adapters are checked-in artifacts paired with each top-level agent Markdown source (including files that use either `.agent.md` or `.md` naming). Their `developer_instructions` payload must remain in parity with the source agent; parity validation normalizes CRLF/LF line endings and trailing whitespace before comparison so Windows checkouts do not produce false stale-adapter failures. Setup copies the TOML and never generates or repairs it. Do not hand-maintain a second domain-guidance implementation. MCP entries are generated from the plugin `.mcp.json` files; unknown same-name Codex entries are conflicts and are never overwritten without an installer ownership marker and `-Force`.

When adding a plugin, add it to `.claude-plugin/marketplace.json`, keep a `skills/*/SKILL.md`, and add any agents or `.mcp.json` under that plugin root. Every top-level agent Markdown file exposed to Codex must have a matching checked-in `.toml` beside it. Run `scripts/validate-codex-catalog.ps1`, then install to a disposable profile and run `scripts/validate-codex-projection.ps1`. A host-specific adapter is allowed only when the host requires metadata or registration that the source artifact cannot provide.

## Support notes

Node/npm is required to activate Fabric or Power BI MCP servers. `uv`, the Power BI Desktop Bridge, ADOMD.NET, and the VS Code Python extension are capability-specific and produce warnings when unavailable; install remediation is shown by the setup workflow. Explicit `-Target Copilot` never writes `.codex`, and explicit `-Target Codex` never writes `.copilot`.
