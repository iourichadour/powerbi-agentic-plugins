## 1. Source and projection

- [x] 1.1 Pin the Power BI Modeling MCP source declaration to the tested package version, remove `--start`, and verify the JSON remains valid.
- [x] 1.2 Add host-specific Windows x64 projection logic for both Codex TOML and the Copilot plugin-local `.mcp.json` while preserving the generic non-Windows declaration, and verify both destinations contain the expected command and arguments.
- [x] 1.3 Preserve installer ownership/conflict behavior and document stale legacy server cleanup; verify unknown user-owned entries are not deleted or overwritten.
- [x] 1.4 Inspect both Copilot profile MCP files, normalize `servers` and `mcpServers`, and detect same-name stale commands; verify the two observed profile files produce one conflict finding rather than two unrelated servers.
- [x] 1.5 Define and test transport-aware MCP identity: compare local stdio and hosted HTTP definitions by transport and launch signature, preserve unowned hosted entries, and use `powerbi-modeling-mcp` as the canonical name with `powerbi-modeling` as a legacy alias.

## 2. Readiness validation and documentation

- [x] 2.1 Add Windows x64 architecture gating, separate package provisioning checks, and bounded MCP `initialize` validation with actionable failure reporting for each selected harness; verify setup does not report MCP ready when the process exits or initialization fails.
- [x] 2.2 Update setup/developer documentation to distinguish MCP registration from package provisioning and describe the Windows platform-package path; verify the documented commands match generated configuration.
- [x] 2.3 Document the Copilot profile-file compatibility behavior and exact remediation for stale profile-level entries; verify both filenames and schemas are covered.

## 3. Regression verification

- [x] 3.1 Extend the setup tests for source parsing, Windows x64 projection, canonical/legacy name handling, transport-aware duplicate behavior, and launch/initialize failure reporting using a deterministic fake launcher; verify the PowerShell test suite passes.
- [x] 3.2 Add regression coverage for profile-level `mcp.json` and `mcp-config.json` conflicts, mirrored definitions, and hosted HTTP/local stdio mismatches without deleting user-owned entries; verify the findings are actionable.
- [x] 3.3 Run OpenSpec validation plus a real Windows x64 MCP smoke test that confirms the pinned platform package remains alive through the initialize exchange; record the results in the change handoff.
