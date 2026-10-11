## 1. ADOMD.NET Resolution and User Environment

- [ ] 1.1 Refactor `setup-team-plugins.ps1` ADOMD.NET discovery to return a canonical DLL-directory result with deterministic compatibility ordering, and verify isolated tests cover a valid override, Program Files, both user NuGet cache layouts, multiple package versions/target frameworks, and no-match behavior.
- [ ] 1.2 Add a validation-and-persistence step that sets process-scoped and current-user `ADOMD_DIR` only after confirming `Microsoft.AnalysisServices.AdomdClient.dll` exists, and verify mocked environment tests cover initial creation, valid-value reuse, invalid-value replacement after successful resolution, read-back failure, and preservation after resolution failure without changing the real developer environment.
- [ ] 1.3 Integrate the persistence result into existing ADOMD download/reuse paths and setup summaries, keeping failures non-fatal, and verify controlled success and failure runs distinguish process-only readiness, persistent readiness, and manual remediation while a non-Power-BI install leaves `ADOMD_DIR` unchanged.
- [ ] 1.4 Add a compatibility verification using the DAX framework Python runtime that loads the selected ADOMD assembly without connecting to a model, and verify an incompatible DLL directory is rejected before setup reports end-to-end readiness.

## 2. Installed DAX Python Runtime

- [ ] 2.1 Add installer logic that runs locked `uv` synchronization against the copied `powerbi/skills/dax-test-framework` at the stable discovery path, and verify a clean temporary installation produces the expected `.venv` interpreter from the committed `pyproject.toml` and `uv.lock`.
- [ ] 2.2 Verify the installed interpreter can import pytest and the shared framework helpers without opening an ADOMD connection, and verify missing `uv`, package-feed failure, and import failure each produce a non-fatal warning with the installed path and exact retry command.
- [ ] 2.3 Wire runtime provisioning after the Power BI plugin copy on both first install and forced reinstall, and verify a changed lock file is synchronized while installs that exclude `powerbi` do not create or modify the framework environment.

## 3. Project-Local Pytest and VS Code Scaffolding

- [ ] 3.1 Add scaffold templates for a thin project-local DAX pytest adapter that resolves the shared framework through an explicit override, source-checkout layout, or standard per-user plugin path, defaults to the target project's `DAXQueries`, and verify adapter tests cover all resolution branches plus an actionable missing-framework diagnostic.
- [ ] 3.2 Add a portable VS Code settings template for the installed framework interpreter and workspace-relative pytest discovery arguments, and verify the generated values contain no absolute installing-user path, credentials, or model-specific source data.
- [ ] 3.3 Extend `setup_project.py` to create the adapter assets and safely create or merge `.vscode/settings.json`, preserving unrelated and conflicting values, and verify temporary-project tests cover new, partial, repeated, malformed-settings, non-conflicting merge, conflicting managed key, and pre-existing Python-test cases.
- [ ] 3.4 Extend scaffolding's text and JSON result contracts to classify destinations as created, already present, merged, or conflicted and return a remediation-required outcome for conflicts, and verify existing automation can still identify the original assertion-library, registry, and `TESTING.md` results.

## 4. Shared Pytest Integration Behavior

- [ ] 4.1 Adapt the shared pytest hooks so a project-local adapter can supply a default model directory while direct pytest continues to accept explicit `--dax-model-dir`, and verify both entry points discover identical `.dax` files for the same project/profile/filter inputs.
- [ ] 4.2 Keep transport creation and the smoke gate out of collection, and verify pytest collection plus VS Code-style discovery succeeds with Power BI Desktop closed and with a fake transport that fails if constructed during collection.
- [ ] 4.3 Normalize missing framework, interpreter, and ADOMD.NET failures into concise actionable diagnostics, including `CONNECTION_ERROR` for executed tests missing ADOMD.NET, and verify none of these execution failures are reported as passed or skipped.
- [ ] 4.4 Add an integration fixture that opens a scaffolded semantic-model folder as the pytest working directory and runs discovery/execution through the provisioned interpreter, and verify selected profile, filename, and environment filters reach the same shared helpers as the direct framework pytest command.

## 5. Documentation and Installer UX

- [ ] 5.1 Update `DEVELOPER_SETUP.md` and installer next-step/troubleshooting output to explain persisted `ADOMD_DIR`, idempotent checks for ADOMD.NET, Power BI Desktop Bridge, and the VS Code Python extension, installed runtime provisioning, required VS Code restart, retry commands, and non-Power-BI behavior, and verify every documented path/command matches the implementation.
- [ ] 5.2 Update the `dax-unit-testing` setup guide and generated `TESTING.md` template to document the new local adapter, VS Code Test Explorer flow, safe settings conflicts, and terminal fallback, and verify a freshly scaffolded guide contains runnable project-relative commands.
- [ ] 5.3 Update the `dax-test-framework` skill documentation to distinguish discovery from execution prerequisites and describe framework-path/ADOMD overrides without requiring project-local DLLs or global Python packages, and verify links and referenced files resolve.

## 6. End-to-End Verification

- [ ] 6.1 Run the repository's DAX framework and unit-testing Python suites through their respective locked `uv` projects and verify all existing and new tests pass.
- [ ] 6.2 In an isolated Windows user/test environment, run `setup-team-plugins.ps1 -PluginName powerbi -Force`, verify user and child-process `ADOMD_DIR`, the installed framework `.venv`, and dependency imports, confirm already-installed external tooling is not reinstalled, then restart VS Code and verify the Python Test Explorer discovers a scaffolded project's DAX tests without manual configuration.
- [ ] 6.3 With a scaffolded semantic model open in Power BI Desktop and PQL.Assert deployed, run one discovered DEV test from VS Code and the equivalent direct pytest command, and verify both use the same files, smoke gate, assertion result, and error classification.
- [ ] 6.4 Run `openspec validate --strict --changes "enable-local-vscode-dax-tests"` and verify all proposal, design, delta-spec, and task artifacts pass validation before requesting implementation approval.
