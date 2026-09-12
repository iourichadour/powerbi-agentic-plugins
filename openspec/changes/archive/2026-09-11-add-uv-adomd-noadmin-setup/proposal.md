## Why

`setup-team-plugins.ps1` installs the `powerbi` plugin but never provisions the two things its
`dax-unit-testing`/`dax-test-framework` skills require to actually run: the `uv` Python tool
itself, and the Windows-only `Microsoft.AnalysisServices.AdomdClient` (ADOMD.NET) client library
that `pyadomd` needs. Developers without admin rights currently hit `uv: command not found` and
then `pyadomd is not installed`/DLL-not-found errors with no automated path to fix them, even
though `dax_test_helpers.py` already knows how to *find* an ADOMD.NET install if one exists. Team
members should be ready to run DAX tests immediately after running the setup script, without a
manual, tribal-knowledge install step.

## What Changes

- Add a no-admin `uv` install step to `setup-team-plugins.ps1`: detect `uv` on `PATH`, and if
  missing, run the official standalone installer so it lands under the current user's profile
  (no elevation, no `Program Files`).
- Add a no-admin ADOMD.NET provisioning step, gated to run only when the `powerbi` plugin is a
  target: detect an existing `Microsoft.AnalysisServices.AdomdClient.dll` in the locations
  `dax_test_helpers.py` already searches (`ADOMD_DIR`, `Program Files\Microsoft.NET\ADOMD.NET`,
  NuGet package caches); if none is found, download the
  `Microsoft.AnalysisServices.AdomdClient` NuGet package from nuget.org, extract it into a
  user-writable cache directory under `%LOCALAPPDATA%`, and fall back to printing manual
  instructions if the download fails (offline, blocked network).
- Add a `pyproject.toml` (and matching `uv.lock`) to `plugins/powerbi/skills/dax-unit-testing/`
  so its scripts are invoked the same way as `dax-test-framework`'s (`uv run --project
  plugins/powerbi/skills/dax-unit-testing ...`), keeping every skill's Python dependencies (or
  lack thereof) resolved from its own scoped project instead of a shared/global environment.
- Update `plugins/powerbi/skills/dax-unit-testing/SKILL.md` and
  `plugins/powerbi/skills/dax-test-framework/SKILL.md` prerequisites sections to point at the
  new automated setup step instead of describing ADOMD.NET/`uv` as manual prerequisites.
- Update `DEVELOPER_SETUP.md` to document the new provisioning steps and the no-admin
  installation locations they use.

## Capabilities

### New Capabilities
- `powerbi/dev-environment-provisioning`: automated, no-admin-rights provisioning of `uv` and the
  ADOMD.NET client library as part of team plugin setup, so DAX testing skills are runnable
  immediately after setup.

### Modified Capabilities
<!-- none: dax-test-framework and dax-unit-testing behavior/requirements are unchanged; only their
     documented prerequisites and dax-unit-testing's Python invocation mechanics change -->

## Impact

- Modified: `setup-team-plugins.ps1` (new `Install-Uv` / `Install-AdomdClient` steps, invoked
  from the main flow when the `powerbi` plugin is targeted).
- New: `plugins/powerbi/skills/dax-unit-testing/pyproject.toml`,
  `plugins/powerbi/skills/dax-unit-testing/uv.lock`.
- Modified: `plugins/powerbi/skills/dax-unit-testing/SKILL.md`,
  `plugins/powerbi/skills/dax-test-framework/SKILL.md`, `DEVELOPER_SETUP.md`.
- Network dependency: the ADOMD.NET provisioning step requires outbound access to
  `nuget.org` during setup; no credentials are involved (the package is public).
- No change to `dax_test_helpers.py`'s existing ADOMD.NET discovery search paths — the new
  download step targets one of those existing NuGet-cache locations so discovery keeps working
  unmodified.
