# Project Memory

## Codex agent adapters

- Codex projects all packaged agent adapters into the shared user directory `%USERPROFILE%\.codex\agents`.
- Every checked-in agent adapter MUST therefore have a globally unique TOML `name` and filename across all plugins. Matching the filename to the `name` is the repository convention.
- Before adding an adapter, check the complete plugin catalog for name and filename collisions. Do not rely on a plugin directory as a Codex namespace.
- Adapter parity validation must normalize CRLF/LF line endings and trailing whitespace before comparing `developer_instructions`; otherwise Windows checkouts can be falsely reported as stale.

## End-of-session workflow

- Update `MEMORY.md` and `SESSION_RESUME.md` before publishing session state.
- Run `scripts/end-session.ps1` with the active OpenSpec change. It validates OpenSpec, reports unchecked tasks without marking them complete, stages only declared handoff files, commits, pushes the Jira branch, creates a PR targeting `DEV`, and prints a Jira-ready update.
- Post the generated commit/PR summary through the configured Jira workflow and transition the ticket only when the actual Jira transition is available.

## Windows Power BI Modeling MCP

- The source declaration remains portable and pinned to `@microsoft/powerbi-modeling-mcp@1.0.0` without `--start`.
- Windows x64 Codex and Copilot projections use `npx.cmd -y @microsoft/powerbi-modeling-mcp-win32-x64@1.0.0 --start`.
- MCP readiness must resolve `npx.cmd` to its absolute executable path before `ProcessStartInfo`; resolving only the literal command causes npm to look for missing repository-local modules.
- Codex signature comparison treats `npx` and `npx.cmd` as equivalent on Windows when the package and arguments match.
- User-owned Copilot profile entries in both `.copilot\mcp.json` (`servers`) and `.copilot\mcp-config.json` (`mcpServers`) are preserved; stale Power BI Modeling entries require manual cleanup.
