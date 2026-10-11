## MODIFIED Requirements

### Requirement: No-Admin ADOMD.NET Client Provisioning
When the `powerbi` plugin is among the setup script's target plugins, the script SHALL check for
an existing, resolvable `Microsoft.AnalysisServices.AdomdClient.dll` in the locations the
`dax-test-framework` transport searches, including an `ADOMD_DIR` override, the on-machine
ADOMD.NET client install, and per-user NuGet package caches. If none is found, the script SHALL
download the `Microsoft.AnalysisServices.AdomdClient` NuGet package from nuget.org and extract it
into a user-writable, per-user cache location, requiring no administrator privileges and no
credentials.

After resolving a valid DLL directory, the script SHALL set `ADOMD_DIR` for the current setup
process and persist the canonical directory as a current-user environment variable so newly
started shells, Python processes, and VS Code instances inherit it. The script SHALL preserve a
valid explicit `ADOMD_DIR`; it SHALL replace an invalid value only after another valid DLL
directory has been resolved. It SHALL NOT report ADOMD.NET as ready unless the persisted value
names a directory containing `Microsoft.AnalysisServices.AdomdClient.dll`.

ADOMD.NET download, validation, or environment-persistence failure SHALL NOT fail the overall
plugin setup; the script SHALL report a warning with actionable manual instructions and continue.

#### Scenario: ADOMD.NET already resolvable through a valid override
- **WHEN** the setup script targets the `powerbi` plugin and `ADOMD_DIR` names a directory containing `Microsoft.AnalysisServices.AdomdClient.dll`
- **THEN** the script SHALL skip the download, retain that canonical directory for the process and current user, and report that ADOMD.NET is available

#### Scenario: ADOMD.NET already resolvable
- **WHEN** the setup script targets the `powerbi` plugin and a valid DLL exists in any searched location
- **THEN** the script SHALL skip the download and SHALL set and persist `ADOMD_DIR` to the resolved DLL directory

#### Scenario: ADOMD.NET missing and downloadable
- **WHEN** the setup script targets the `powerbi` plugin, no existing ADOMD.NET client is found, and nuget.org is reachable
- **THEN** the script SHALL download and extract the client library without elevation, select a compatible directory containing the DLL, and set and persist that directory as `ADOMD_DIR`

#### Scenario: Invalid override is replaced only after successful resolution
- **WHEN** `ADOMD_DIR` is set to a missing or invalid directory and the setup script subsequently resolves a valid ADOMD.NET DLL elsewhere
- **THEN** the script SHALL replace the process and current-user values with the valid canonical DLL directory and SHALL report the replacement without exposing sensitive data

#### Scenario: ADOMD.NET download fails without breaking setup
- **WHEN** no valid ADOMD.NET directory can be resolved or downloaded
- **THEN** the script SHALL leave any previously persisted user value unchanged, warn with the failure and manual recovery instructions, and continue the remaining setup steps

#### Scenario: Environment persistence failure is not reported as success
- **WHEN** a valid DLL directory is resolved but the current-user `ADOMD_DIR` value cannot be persisted
- **THEN** the script SHALL retain the usable process-scoped value, warn that future processes require manual configuration, and continue setup without claiming persistent readiness

#### Scenario: New VS Code process inherits ADOMD_DIR
- **WHEN** setup has persisted a valid current-user `ADOMD_DIR` and the user starts or restarts VS Code
- **THEN** Python tests launched by VS Code SHALL inherit the same valid directory without requiring a workspace-specific secret or manual environment entry

#### Scenario: Plugin not targeted skips ADOMD.NET provisioning
- **WHEN** the setup script's target plugins do not include `powerbi`
- **THEN** the script SHALL skip ADOMD.NET provisioning and SHALL NOT change `ADOMD_DIR`

## ADDED Requirements

### Requirement: Power BI external tooling checks are idempotent
When setup targets the `powerbi` plugin, it SHALL detect the Power BI Desktop Bridge CLI,
ADOMD.NET client, and VS Code Python extension before provisioning them. Re-running setup,
including with force-enabled plugin replacement, SHALL reuse each resolvable dependency rather
than reinstalling it, while missing dependencies remain actionable and non-fatal where the
capability is optional.

#### Scenario: Existing external tooling is reused
- **WHEN** the Power BI plugin is targeted and the Desktop Bridge CLI, ADOMD.NET DLL, or `ms-python.python` extension is already available
- **THEN** setup reports that dependency as already installed or available and skips its installer

#### Scenario: Missing external tooling is provisioned
- **WHEN** the Power BI plugin is targeted and one of the supported external dependencies is absent
- **THEN** setup attempts to provision that dependency and reports a warning with manual remediation if provisioning fails

### Requirement: Installed DAX Test Runtime Provisioning
When the `powerbi` plugin is targeted and `uv` is available, the setup script SHALL provision the
locked Python environment for the installed `dax-test-framework` copy at its stable per-user plugin
discovery location. The resulting interpreter SHALL contain the framework's declared runtime and
pytest dependencies and SHALL be addressable by project-local VS Code test configuration without
requiring a global Python package installation. Provisioning failure SHALL be non-fatal and SHALL
identify the command a user can run to retry it.

#### Scenario: Power BI install provisions the locked environment
- **WHEN** the setup script installs the `powerbi` plugin and `uv` is resolvable
- **THEN** it SHALL synchronize the installed `dax-test-framework` environment from its committed manifest and lock file and SHALL verify that the environment's Python can import pytest and the framework helpers

#### Scenario: Existing environment is synchronized after plugin update
- **WHEN** a Power BI plugin reinstall changes the framework manifest or lock file
- **THEN** setup SHALL synchronize the installed environment to the newly installed lock state rather than relying on packages left by the prior plugin version

#### Scenario: Runtime provisioning failure remains recoverable
- **WHEN** the locked Python environment cannot be provisioned
- **THEN** setup SHALL warn with the installed framework path and an actionable `uv` retry command, continue plugin installation, and avoid reporting VS Code DAX testing as ready
