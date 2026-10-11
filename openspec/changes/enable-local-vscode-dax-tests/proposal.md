## Why

The team installer can download ADOMD.NET, but it does not persist the resolved DLL directory as
`ADOMD_DIR`, and a scaffolded semantic-model project does not contain a project-local pytest entry
point or VS Code test configuration. As a result, developers can complete plugin setup yet still
need manual environment and command-line wiring before DAX tests are discoverable and runnable from
the VS Code Python Test Explorer.

## What Changes

- Make `setup-team-plugins.ps1` resolve a usable ADOMD.NET DLL directory whenever the Power BI
  plugin is installed and persist that directory as the current user's `ADOMD_DIR`, while also
  updating the installer process so immediate verification uses the same value.
- Preserve explicit user choices: reuse a valid existing `ADOMD_DIR`, replace an invalid value only
  after a valid installation is found, and keep ADOMD.NET provisioning non-fatal when no valid DLL
  can be resolved.
- Extend DAX project scaffolding with a project-local pytest adapter and configuration that target
  the semantic model's own `DAXQueries` directory while reusing the installed
  `dax-test-framework` implementation rather than duplicating its execution logic.
- Configure the scaffolded project so the VS Code Python extension can discover and run the DAX
  pytest suite from the local project folder using the skill's isolated Python environment and the
  inherited user-level `ADOMD_DIR`.
- Add automated coverage for environment persistence, idempotent project scaffolding, path
  resolution, pytest discovery, and clear diagnostics when the installed framework or ADOMD.NET
  cannot be resolved.
- Update setup and testing documentation to describe the zero-manual-configuration path and the
  remaining override/failure recovery behavior.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `powerbi/dev-environment-provisioning`: Require the Power BI plugin installation path to persist a
  validated per-user `ADOMD_DIR` that is available to future shells and VS Code processes.
- `powerbi/dax-unit-testing`: Extend one-time semantic-model project scaffolding with idempotent,
  project-local pytest and VS Code test-discovery assets.
- `powerbi/dax-test-framework`: Require project-local and VS Code Python Test Explorer execution to
  delegate to the shared DAX framework with the same discovery, smoke-gate, and assertion semantics
  as command-line execution.

## Impact

- `setup-team-plugins.ps1` ADOMD.NET detection, installation, user-environment persistence, and
  validation.
- `plugins/powerbi/skills/dax-unit-testing/assets/scripts/setup_project.py`, its templates, tests,
  and setup documentation.
- `plugins/powerbi/skills/dax-test-framework` pytest integration, path resolution, tests, and skill
  documentation.
- User-scoped Windows environment (`ADOMD_DIR`) and newly scaffolded files under target
  `*.SemanticModel` project folders, including VS Code workspace settings where safe to merge.
- Existing command-line runners and DAX test semantics remain compatible; no breaking behavior is
  intended.
