## Why

There is no reusable, repeatable way in this repo to unit-test Power BI semantic model measures, execute the same DAX suite locally and in Fabric, or certify business-approved values. An external reference implementation demonstrates a working pattern: curated PQL.Assert functions, DAX Query View suites, a smoke gate, a shared `pyadomd` transport, DEV/CLOUD execution, CLI and pytest entry points, notebooks, and JUnit/Markdown reports. This change incorporates those behaviors into shareable Power BI skills and agents without retaining source-repository names, paths, or model-specific assertions.

## What Changes

- Add a `dax-unit-testing` skill to `plugins/powerbi/skills/` staging the PQL.Assert assertion library (`functions.tmdl`), model-independence and reserved-word references, the `Certification/MeasureCertification.csv` registry schema (columns, `TestCategory`/`Status`/`ApprovalSource` lifecycle, `FilterExpression` rules, integrity checklist), and registry automation scripts (`validate_registry.py`, `generate_measure_tests.py`, `certify_measures.py`, `coverage_report.py`, `setup_project.py`).
- Add two onboarding template assets to `dax-unit-testing`: a starter `MeasureCertification.template.csv` (correct header, one illustrative row per `TestCategory`/`Status`/`ApprovalSource` combination, no fabricated business values) and a generalized `TESTING.template.md` (adapted from a reference project's testing guide, with all model-specific names replaced by placeholders). A one-time `pql-tester setup` mode scaffolds both templates into a target semantic model project — creating `Certification/MeasureCertification.csv` and `TESTING.md` only if they do not already exist — so a user adopting the framework is handed a ready-to-fill registry and a project-local testing guide rather than having to author either from scratch.
- Add a `dax-test-framework` skill containing the reusable execution pattern: `dax_test_helpers.py`, the standalone `run_dax_tests.py` runner, the required pytest wrapper, DEV/CLOUD notebooks, environment and file filters, smoke-gate behavior, ADOMD.NET setup guidance, and JUnit/Markdown reporting. The skill shall use target-project paths and configuration rather than hard-coded model names.
- Add a repository-agnostic HTML dashboard asset that loads JUnit XML artifacts at runtime, supports cache-busted refresh and local XML file selection, and renders pass/fail/error summaries, suite health, searchable assertion details, and source metadata without embedding test results in the HTML.
- Include sanitized sample artifacts for the dashboard and skill evaluations: representative CLI JUnit XML, pytest JUnit XML, and Markdown failure-summary files. Samples must demonstrate the supported schemas without containing repository-specific names, credentials, or live business values.
- Add model-wide **test coverage statistics** reporting (`coverage_report.py`): read-only % of measures with any registry row (vs. untested), % with executable `Structural`/developer-certified/business-certified rows, and a `TestCategory` × `Status` × `ApprovalSource` breakdown, emitted as `reports/coverage.json` and `reports/coverage-summary.md`.
- Add a dedicated `pql-tester` agent (`plugins/powerbi/agents/pql-tester.agent.md`) with explicit, separately-invoked operating modes: `scan`, `sync`, `generate`, `run`, `report` (including coverage stats), `diagnose` — plus guardrails preventing fabrication of business-approved values, tolerance-widening, silencing failures, or modifying production model objects.
- Update `powerbi-architect.agent.md` to plan a progressive test-task pattern (`sync` → developer baseline certification → `generate`+`run`, followed by optional additive business certification) for every new/modified measure in specs authored after this change lands.
- Update `powerbi-developer.agent.md` and `semantic-model-authoring/SKILL.md` to route test-generation requests to `pql-tester`/`dax-unit-testing`.
- Update `plugins/powerbi/README.md`, `AGENTS.md`, and `CLAUDE.md` to register the new skill and agent, including that the one-time `pql-tester setup` step is the mechanism (for both the Copilot CLI and Claude Code) that produces a target project's `TESTING.md` and starter `MeasureCertification.csv`.
- Add a skill-creator evaluation set and implementation task for rating both skills against realistic test prompts, including quantitative assertions for smoke-gate enforcement, dual-profile routing, registry safety, dynamic XML report loading, and report generation. The evaluation loop runs after the skill draft exists and uses `generate_review.py` for human review.

## Capabilities

### New Capabilities
- `powerbi/dax-unit-testing`: DAX Query View unit-testing skill — assertion library staging, the measure certification registry contract (schema, lifecycle, integrity rules), the validate/generate/certify/coverage automation scripts, and the progressive certification workflow (Structural, developer-certified, then optional business-certified checks).
- `powerbi/dax-test-framework`: reusable dual-profile DAX execution framework — typed ADOMD.NET transport, dynamic Desktop-port discovery, Fabric XMLA credentials, smoke gate, file/environment filtering, CLI/pytest/notebook runners, and JUnit/Markdown reports.
- `powerbi/pql-tester-agent`: dedicated testing agent — its operating modes (scan/sync/generate/run/report/diagnose), the developer-certification and business-value guardrails, and its write-scope/secret-handling constraints.
- `powerbi/architect-test-planning`: `powerbi-architect` agent's requirement to emit the sync → developer-certification → generate/run chain, with optional additive business-certification tasks, for every new or modified measure in specs authored after this change.

### Modified Capabilities
<!-- none: openspec/specs has no existing capabilities yet, so every behavior introduced here is new -->

## Impact

- New: `plugins/powerbi/skills/dax-unit-testing/**` (SKILL.md, references/, assets/, assets/scripts/, assets/templates/).
- New: `plugins/powerbi/skills/dax-test-framework/**` (SKILL.md, scripts/, notebook templates, HTML dashboard, and sanitized XML/Markdown sample artifacts).
- New: `plugins/powerbi/agents/pql-tester.agent.md`.
- Modified: `plugins/powerbi/agents/powerbi-architect.agent.md`, `plugins/powerbi/agents/powerbi-developer.agent.md`, `plugins/powerbi/skills/semantic-model-authoring/SKILL.md`, `plugins/powerbi/README.md`, `AGENTS.md`, `CLAUDE.md`, `.claude-plugin/marketplace.json` (version bump for the `powerbi` plugin and the root marketplace metadata).
- Depends on a `uv`-resolvable Python dependency manifest for the ADOMD.NET transport (`pythonnet`, `pyadomd`) and pytest; this must stay aligned with the sibling `add-python-powerbi-dependency-checking` change.
- `validate_registry.py` must offer a `--schema-only` mode, because the model-existence integrity rule cannot be evaluated in CI or against the shipped registry template where no semantic model is available.
- Depends on the PQL.Assert 0.6.0 assertion functions/UDF library; only the functions needed by a target model's tests are staged rather than importing unrelated rule libraries.
- The external reference generator uses an 11-column registry (`MeasureName, TestName, TestCategory, FilterExpression, ExpectedValue, Tolerance, Owner, Status, Severity, RequirementId, LastReviewed`), while the reusable contract adds approval-audit columns. The implementation must provide an explicit legacy-schema migration or refuse ambiguous approved rows; it must not guess `ApprovalSource`, `ApprovedBy`, or approval dates.
- Source-repository model assets, measure lists, report-specific assertions, and live credentials are reference fixtures only and must not be copied into the plugin repository.
- No changes to existing `dax-data-quality` skill (Power Query row-level checks remain separate from DAX Query View unit assertions).
- Does not implement GATE-001's own CI/PR enforcement plumbing — this change is a dependency GATE-001 consumes, not GATE-001 itself.
