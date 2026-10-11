## MODIFIED Requirements

### Requirement: CLI, Pytest, and Notebook Entry Points

The framework SHALL provide a standalone CLI runner, a pytest wrapper, DEV/CLOUD notebook
templates, and a thin project-local pytest integration contract that all use the same helper,
transport, discovery, smoke-gate, and result-parsing logic. Python tooling SHALL be invocable via
documented `uv run` commands and through the Python interpreter provisioned for the installed
framework. Notebook configuration SHALL make profile, model path, and filters explicit rather than
embedding a model-specific path.

The project-local pytest integration SHALL be discoverable when pytest's working directory is the
semantic model project, SHALL default its model directory to that project, and SHALL support the
same DEV/CLOUD profile and filename/environment filters as the framework's direct pytest entry
point. Test collection SHALL not connect to Power BI Desktop or Fabric; connection and smoke-gate
work SHALL begin only when the collected DAX test is executed. If the shared installed framework,
its interpreter, or ADOMD.NET cannot be resolved, the integration SHALL return an actionable
diagnostic rather than an import traceback or a false passing/skipped result.

#### Scenario: Both runners use the same suite
- **WHEN** the CLI and direct pytest wrapper run against the same profile and model directory
- **THEN** both SHALL discover the same `.dax` files and apply the same smoke gate and assertion semantics

#### Scenario: VS Code discovers project-local DAX tests without connecting
- **WHEN** the VS Code Python extension performs pytest discovery from a scaffolded semantic model project
- **THEN** it SHALL collect the project-local DAX test cases without opening an ADOMD.NET connection or requiring Power BI Desktop to be running during discovery

#### Scenario: VS Code execution uses shared framework semantics
- **WHEN** a developer runs a discovered DAX test from the VS Code Python Test Explorer
- **THEN** the test SHALL execute through the installed framework using the semantic model project's `DAXQueries` directory, selected profile and filters, and the same smoke gate and result classification as direct pytest execution

#### Scenario: User-level ADOMD_DIR is sufficient
- **WHEN** the installed framework interpreter inherits a valid current-user `ADOMD_DIR`
- **THEN** project-local CLI and VS Code test execution SHALL resolve `Microsoft.AnalysisServices.AdomdClient.dll` without a project-local copy or workspace-specific environment setting

#### Scenario: Missing installed framework is actionable
- **WHEN** the project-local adapter cannot resolve the installed `dax-test-framework` or its provisioned interpreter
- **THEN** test discovery or execution SHALL fail with a concise diagnostic naming the expected location and the team setup command needed to repair the installation

#### Scenario: Missing ADOMD.NET is not a skipped or passing test
- **WHEN** a collected DAX test is executed without a resolvable ADOMD.NET DLL
- **THEN** execution SHALL fail with `CONNECTION_ERROR`, identify `ADOMD_DIR` or team setup as remediation, and SHALL NOT report the test as skipped or passed
