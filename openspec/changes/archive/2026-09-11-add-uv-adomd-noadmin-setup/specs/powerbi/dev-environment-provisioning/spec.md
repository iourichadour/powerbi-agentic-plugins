## Purpose

Ensures every developer running the team plugin setup script ends up with a working `uv`
installation and, when the `powerbi` plugin is targeted, a resolvable ADOMD.NET client library —
both installed without administrator rights — so DAX testing skills are runnable immediately
after setup instead of failing with missing-tool or missing-DLL errors.

## ADDED Requirements

### Requirement: No-Admin `uv` Provisioning
The team setup script SHALL detect whether `uv` is resolvable on the current user's `PATH` before
installing plugins, and if it is not, SHALL install `uv` using a method that requires no
administrator privileges and installs entirely under the current user's profile. The script
SHALL NOT fail the overall setup run if `uv` installation fails; it SHALL report a warning with
manual install instructions and continue installing plugins.

#### Scenario: `uv` already installed
- **WHEN** the setup script runs and `uv` is already resolvable on `PATH`
- **THEN** the script SHALL skip installation and report that `uv` is present, without re-running the installer

#### Scenario: `uv` missing and installable
- **WHEN** the setup script runs and `uv` is not resolvable on `PATH`
- **THEN** the script SHALL install `uv` under the current user's profile without requesting elevation, and SHALL report success once `uv` is resolvable afterward

#### Scenario: `uv` install fails without breaking setup
- **WHEN** the `uv` installation step fails (for example, no network access)
- **THEN** the script SHALL report a warning naming the failure and manual install instructions, and SHALL continue with the remaining setup steps rather than aborting

### Requirement: No-Admin ADOMD.NET Client Provisioning
When the `powerbi` plugin is among the setup script's target plugins, the script SHALL check for
an existing, resolvable `Microsoft.AnalysisServices.AdomdClient.dll` in the locations the
`dax-test-framework` transport already searches (an `ADOMD_DIR` override, the on-machine ADOMD.NET
client install, and per-user NuGet package caches). If none is found, the script SHALL download
the `Microsoft.AnalysisServices.AdomdClient` NuGet package from nuget.org and extract it into a
user-writable, per-user cache location that the existing search already covers, requiring no
administrator privileges and no credentials. The script SHALL NOT fail the overall setup run if
this step fails; it SHALL report a warning with manual install instructions and continue.

#### Scenario: ADOMD.NET already resolvable
- **WHEN** the setup script targets the `powerbi` plugin and a valid `Microsoft.AnalysisServices.AdomdClient.dll` already exists in a searched location
- **THEN** the script SHALL skip the download and report that ADOMD.NET is already available

#### Scenario: ADOMD.NET missing and downloadable
- **WHEN** the setup script targets the `powerbi` plugin, no existing ADOMD.NET client is found, and nuget.org is reachable
- **THEN** the script SHALL download and extract the client library into a per-user cache location without requiring elevation, such that the existing ADOMD.NET discovery logic used by `dax-test-framework` resolves it on the next run

#### Scenario: ADOMD.NET download fails without breaking setup
- **WHEN** the download from nuget.org fails (for example, no network access or the endpoint is blocked)
- **THEN** the script SHALL report a warning naming the failure and manual install instructions (including the `ADOMD_DIR` override), and SHALL continue with the remaining setup steps rather than aborting

#### Scenario: Plugin not targeted skips ADOMD.NET provisioning
- **WHEN** the setup script's target plugins do not include `powerbi`
- **THEN** the script SHALL skip the ADOMD.NET provisioning step entirely

### Requirement: Per-Skill Isolated Python Environments
Each Power BI plugin skill that ships Python scripts SHALL declare its own `uv`-resolvable
dependency manifest (`pyproject.toml`, with a matching lock file when it has third-party
dependencies), so its scripts are invoked from a project-scoped environment resolved by `uv run
--project <skill-directory>` rather than a shared or global Python environment. This SHALL hold
even for a skill whose scripts currently use only the standard library.

#### Scenario: Stdlib-only skill still gets a scoped project
- **WHEN** a skill's Python scripts import only standard-library modules
- **THEN** the skill SHALL still declare its own `pyproject.toml` so `uv run --project <skill-directory>` resolves and runs its scripts without depending on any other skill's environment

#### Scenario: Two skills' dependencies never collide
- **WHEN** two sibling skills each declare their own `pyproject.toml` with different (or no) third-party dependencies
- **THEN** running one skill's scripts via `uv run --project <that skill's directory>` SHALL NOT require or be affected by the other skill's dependency manifest
