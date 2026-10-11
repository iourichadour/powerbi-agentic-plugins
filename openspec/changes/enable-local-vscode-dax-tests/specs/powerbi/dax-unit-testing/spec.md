## MODIFIED Requirements

### Requirement: Idempotent Project Scaffolding

The skill SHALL provide a deterministic, separately invocable scaffolding entry point that deploys
the selected PQL.Assert assertion functions into a target semantic model's assertion-library
definition file; copies `MeasureCertification.template.csv` to
`Certification/MeasureCertification.csv` and `TESTING.template.md` to `TESTING.md`; and creates a
project-local pytest adapter and VS Code Python test-discovery configuration for the semantic
model's own `DAXQueries` directory.

The project-local adapter SHALL delegate execution to the installed `dax-test-framework` and SHALL
NOT duplicate its transport, smoke-gate, discovery, or assertion implementation. Generated
configuration SHALL use user-independent path expressions where supported, SHALL contain no
credentials, and SHALL make the target model directory explicit. Scaffolding SHALL create its
owned destination files only when absent, SHALL leave pre-existing test files byte-identical, and
SHALL preserve unrelated VS Code settings. When an existing setting conflicts with a required
managed value, scaffolding SHALL report the conflict and its exact remediation rather than
silently replacing the user's setting.

Scaffolding SHALL report every created, already-present, merged, or conflicted destination and
SHALL NOT write to any semantic model object other than the assertion-library definition file.

#### Scenario: New project receives a runnable local pytest surface
- **WHEN** scaffolding runs against an unscaffolded semantic model project
- **THEN** it SHALL create the assertion library, registry, testing guide, project-local pytest adapter, and VS Code pytest configuration needed to discover that adapter from the project folder

#### Scenario: VS Code configuration contains no machine-specific absolute path
- **WHEN** scaffolding creates VS Code test settings
- **THEN** the settings SHALL locate the per-user installed framework runtime through portable user-environment path expansion and SHALL NOT embed the installing user's absolute profile path

#### Scenario: Second scaffolding run makes no changes
- **WHEN** scaffolding runs against a project that has already been scaffolded
- **THEN** it SHALL leave every owned destination file byte-identical, preserve unrelated VS Code settings, and report each destination as already present or already configured

#### Scenario: Partially scaffolded project is completed, not overwritten
- **WHEN** scaffolding runs against a project that has `Certification/MeasureCertification.csv` but lacks `TESTING.md` and the local pytest adapter
- **THEN** it SHALL create only the missing assets and SHALL leave the existing registry and test files unmodified

#### Scenario: Existing VS Code settings are merged safely
- **WHEN** `.vscode/settings.json` exists with unrelated settings and no conflicting values for the scaffold-managed pytest keys
- **THEN** scaffolding SHALL add only the missing managed pytest values and SHALL preserve all unrelated settings

#### Scenario: Conflicting VS Code test configuration is not overwritten
- **WHEN** `.vscode/settings.json` contains a different value for a scaffold-managed pytest setting
- **THEN** scaffolding SHALL preserve the existing value, report the conflicting key and required value, and return an outcome that indicates manual remediation is required

#### Scenario: Existing project tests remain untouched
- **WHEN** the target project already contains Python tests outside the scaffold-owned DAX adapter paths
- **THEN** scaffolding SHALL neither overwrite nor relocate those tests and SHALL configure DAX discovery without excluding them
