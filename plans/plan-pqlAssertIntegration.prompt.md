# Plan: Integrate PQL.Assert DAX Unit Testing Framework (FIN-1787)

This plan integrates the **PQL.Assert** automated DAX unit testing library and testing workflow from `C:\Development\PQL.Assert` into this repository under `plugins/powerbi/`. The integration provides a dedicated test engineer agent (`pql-tester`), a comprehensive testing skill (`dax-unit-testing`) with 100+ assertion functions, a **CSV-based measure certification registry contract** (per GATE-001 — see below), and a Fabric notebook runner asset for automated batch testing across models.

Development is active on compliant branch `feature/FIN-1787-glasslake-testing-framework` linked to Jira ticket **FIN-1787** ("Glasslake Testing Framework").

**Governance alignment (GATE-001):** the BI COE's "Measure Certification & Testing" gate (`GATE-001-measure-certification.prompt.md`) specifies that a **business-approved value** for a `Certification`/`Aggregation`/`Regression` test must come from a business owner, not be invented or guessed by an agent — but the agent is not locked out of the registry entirely. `pql-tester` generates and self-approves `Structural` tests on its own (they assert integrity only — "does it evaluate", "is it not blank" — no business judgment involved) and seeds the `Certification/MeasureCertification.csv` template for each new measure; a business owner or analyst then supplies the business-value rows. If that value is stated explicitly by a human in the same request (not guessed), `pql-tester` can write it into the row and set `Status=Approved` itself — recording a stated value isn't the same as inventing one. This plan adopts that two-track registry model as the mechanism `dax-unit-testing`/`pql-tester` use to plan and generate tests — it supplies the reusable skill/agent capability GATE-001 depends on; it does **not** implement GATE-001's own CI/PR enforcement (see Scope & Boundaries).

---

### Step-by-Step Implementation

#### Phase 1: Skill Structure & Reference Assets
1. **Create Skill Folder Hierarchy**:
   - Establish `plugins/powerbi/skills/dax-unit-testing/` with `references/` and `assets/` (including an `assets/scripts/` subfolder for the registry automation) subdirectories.
2. **Combine & Stage Assertion Library TMDL**:
   - Combine PQL.Assert library files from `C:\Development\PQL.Assert\src\lib\*.tmdl` into a single, clean `functions.tmdl` and stage it at `plugins/powerbi/skills/dax-unit-testing/references/functions.tmdl`.
3. **Stage Supporting Guidelines**:
   - Stage `plugins/powerbi/skills/dax-unit-testing/references/model-independence.md` (from PQL.Assert's `model-independence/SKILL.md`) covering model-independent UDF design using row iteration.
   - Stage `plugins/powerbi/skills/dax-unit-testing/references/reserved-dax-words.md` for DAX syntax safety.
4. **Stage Certification Registry Schema Reference** (from GATE-001 §5):
   - Create `plugins/powerbi/skills/dax-unit-testing/references/certification-registry-schema.md` defining the `Certification/MeasureCertification.csv` contract that ships inside every *target* semantic model project (not this skills repo — the skill teaches and tools the pattern, each customer project owns its own registry file). Document:
     - The exact column schema, in order: `MeasureName, TestName, TestCategory, FilterExpression, ExpectedValue, Tolerance, Owner, Status, Severity, RequirementId, LastReviewed`.
     - `TestCategory` definitions: `Structural` (integrity only, no business value), `Certification` (business-approved value + `FilterExpression`), `Aggregation` (parts sum to whole), `Regression` (previously certified period stays unchanged).
     - The `Status` lifecycle: `Pending` (placeholder, no approved value yet) → `Approved` (business-signed-off, eligible for generation) → `Retired` (skipped at execution, retained for audit).
     - The `FilterExpression` rule: must be valid DAX droppable straight into `CALCULATE` (e.g. `KEEPFILTERS('Date'[Month]="2026-03")`), comma-separated for multiple filters, quoted in CSV because it contains commas, empty only when `TestCategory=Structural`.
     - The full integrity-rule checklist a validator must enforce: header matches schema exactly; `MeasureName`+`TestName` unique; `MeasureName` exists in the model; `TestCategory` is a permitted value; `FilterExpression` non-empty unless Structural; `ExpectedValue` numeric or one of `NOT_BLANK`/`>=0`/`>0` when Approved (never `TBD`); `Tolerance` numeric `>= 0`; `Status`/`Severity` are permitted values; `LastReviewed` is a valid ISO date when Approved; `Retired` rows are skipped but retained.
5. **Stage Registry Automation Scripts** (from GATE-001 §7–§8, principle: "prefer deterministic scripts over agent reasoning for anything that runs in CI"):
   - Add three reusable scripts to `plugins/powerbi/skills/dax-unit-testing/assets/scripts/`:
     - `validate_registry.py` — enforces every rule from the schema reference; fails distinctly with error type `REGISTRY_INVALID` rather than a generic assertion failure.
     - `generate_measure_tests.py` — converts `Status=Approved` rows into one `.dax` file per measure (`DAXQueries/<MeasureNamePascalCase>.ANY.Tests.dax`), each a single `UNION(...)` of `PQL.Assert` calls (equality assertion when `Tolerance=0`, else range/approximate assertion). `Status=Pending` rows are skipped and reported as `CERTIFICATION_PENDING`; `Status=Retired` rows are skipped entirely. Generation is idempotent (byte-identical output for identical input), carries a `DO NOT EDIT BY HAND` header, and uses a content-hash check to fail as `GENERATED_FILE_MODIFIED` instead of silently overwriting a hand-edited file.
     - `certify_measures.py` — `scan` (read-only metadata compliance report: description, format string, display folder, home table, registry coverage) and `sync` (reconcile registry against the model: for a new measure, auto-generate **and auto-approve** its `Structural` row(s) — e.g. `NOT_BLANK`, `Owner=BI COE`, `Status=Approved` — since these carry no business judgment, then append a `Status=Pending` placeholder `Certification` row (`ExpectedValue=TBD`, `Owner=TBD`) for the business-value test; flag — never auto-delete — orphaned rows for renamed/deleted measures). Neither mode may *guess* `FilterExpression`, `ExpectedValue`, `Owner`, or `RequirementId` for a `Certification`/`Aggregation`/`Regression` row — but both may **write or update** those fields, including flipping `Status` to `Approved`, when a human explicitly supplies the value in the same request; the rule is against fabrication, not transcription.
     - `coverage_report.py` — read-only test coverage statistics generator: connects to the model (DEV local Desktop or CLOUD via XMLA, same two profiles as the runner) to enumerate every measure, cross-references `Certification/MeasureCertification.csv`, and computes per-model coverage: overall % of measures with ≥1 registry row at all (vs. **untested** — zero rows), % with an `Approved` `Structural` row, % with an `Approved` `Certification`/`Aggregation`/`Regression` row, a breakdown by `TestCategory` × `Status`, and a breakdown by display folder/home table so gaps can be triaged by area. Emits both a machine-readable `reports/coverage.json` (for CI thresholds/badges) and a human-readable `reports/coverage-summary.md` (table + a flat list of untested measures). Purely additive/read-only — never writes to the registry or the model, and never blocks or fails a build itself (that gating belongs to the consuming project's own CI, same boundary as GATE-001's enforcement).
6. **Stage Cleaned Fabric Test Runner Notebook**:
   - Copy `RunPQLAssertTests.ipynb` to `plugins/powerbi/skills/dax-unit-testing/assets/RunPQLAssertTests.ipynb` with all execution output and session metadata stripped.
7. **Author Skill Instructions**:
   - Create `plugins/powerbi/skills/dax-unit-testing/SKILL.md` covering:
     - Getting started: deploying `functions.tmdl` into a semantic model (via `powerbi-modeling-mcp` or TMDL import)
     - Test creation workflow in DAX Query View (`.dax` files in `[Model].SemanticModel\DAXQueries\`) and `daxQueries.json` tab registry
     - Environment governance (DEV, TEST, PROD, ANY)
     - Complete assertion taxonomy (Basic, Equality, Numeric, String, Column, Table, Relationship, Partition, Perspective, OLS, Best Practice)
     - Fabric notebook execution pattern
     - **Registry-driven certification workflow** (new), a two-track model: **Track A (Structural)** — `sync` auto-generates and auto-approves the integrity test for every measure (no business input needed) → straight to `generate`/`run`. **Track B (Certification/Aggregation/Regression)** — `sync` appends a `Status=Pending` placeholder → **business input** (external, human-supplied — the agent must never *invent or guess* `ExpectedValue`/`Owner`, but *may* write them and flip `Status` to `Approved` once a human has explicitly stated the value, whether via chat, spec, or ticket) → `generate` (Approved rows only, via the Phase 1 scripts) → `run` (DEV via local Desktop, or CLOUD via XMLA — both profiles produce identical artifacts) → `report`/`diagnose` (read-only results and failure hypotheses; never auto-repairs).
     - The full error-type vocabulary (`VALUE_MISMATCH`, `BLANK_RESULT`, `DAX_ERROR`, `MEASURE_NOT_FOUND`, `CERTIFICATION_PENDING`, `METADATA_INCOMPLETE`, `REGISTRY_INVALID`, `GENERATED_FILE_MODIFIED`, `CONNECTION_ERROR`) so any downstream CI gate built on top of this skill (e.g. a GATE-001-style pipeline) gets a consistent, machine-readable contract without this skill owning CI/PR plumbing itself.
     - **Test coverage statistics** (new): how to run `coverage_report.py` (standalone, or via `pql-tester`'s `report` mode) to answer "how much of this model is tested?" — the model-vs-registry cross-reference it computes, the `coverage.json`/`coverage-summary.md` artifacts it emits, and how to read the untested-measures list to prioritize the next `sync` pass. Coverage stats are a snapshot of registry state, not a substitute for running the generated `.dax` tests — a measure can be 100% "covered" by rows that are still `Pending`.

#### Phase 2: Dedicated Testing Agent
8. **Author `pql-tester.agent.md`**:
   - Create `plugins/powerbi/agents/pql-tester.agent.md` configured for Claude Haiku 4.5 with tools `vscode`, `read`, `edit`, `agent`, `powerbi-modeling-mcp/*`.
   - Define explicit, separately-invoked operating modes mirroring GATE-001's Measure Certification Agent: `scan` (read-only), `sync` (registry reconciliation — auto-generate **and auto-approve** `Structural` rows since they need no business judgment; append `Status=Pending` placeholders for `Certification`/`Aggregation`/`Regression` rows; flag orphans; never *guess* a business value), `generate` (Approved rows → `.dax` files via the Phase 1 scripts), `run` (DEV/CLOUD execution), `report` (emit results **and, via `coverage_report.py`, model-wide test coverage statistics** — % of measures with any registry row, % with an `Approved` `Structural` row, % with an `Approved` `Certification`/`Aggregation`/`Regression` row, and the untested-measures list — read-only, never triggers `sync`/`generate` on its own), `diagnose` (read-only failure hypothesis: classification, evidence, recommended checks, confidence — never auto-resolves). The agent must never run `sync` or `generate` silently as a side effect of `scan`/`run`/`report`. On explicit request — e.g. the user or business owner directly supplies a `FilterExpression`/`ExpectedValue`/`Owner` in the conversation — `sync` (or a direct edit) may create or update that `Certification` row and set `Status=Approved`; this is recording a stated value, not inventing one, and is explicitly allowed.
   - Specify strict semantic model testing constraints: verify `PQL.Assert` installation, create tests only in root `DAXQueries/`, maintain `daxQueries.json`, follow `[Area].[Environment].Test(s)` naming convention, combine assertions with `UNION`, and strictly avoid modifying production measures or model logic.
   - Bake in guardrails from GATE-001 §14, refined to distinguish fabrication from transcription: never invent, estimate, or guess an `ExpectedValue` the agent wasn't explicitly given — but it may write down and self-approve a value a human just stated, and may always self-approve `Structural` rows outright; never widen `Tolerance` to make a failing test pass; never set `Status=Approved` on a `Certification`/`Aggregation`/`Regression` row without an explicit human-supplied value; never set `Status=Retired` to silence a failure; never delete or disable a failing test; never modify semantic model objects; write only within `Certification/`, `DAXQueries/`, `reports/`, and `TESTING.md`; never embed, print, or log secrets — CLOUD-profile credentials are read from environment variables only (`PBI_WORKSPACE`, `PBI_MODEL`, `PBI_CLIENT_ID`, `PBI_TENANT_ID`, `PBI_CLIENT_SECRET`).

#### Phase 3: Ecosystem Wiring, Documentation & Planning Integration
9. **Update Power BI Plugin Metadata**:
   - Update `plugins/powerbi/README.md` to document the `pql-tester` agent and `dax-unit-testing` skill.
10. **Update Developer Agent & Authoring Skill Routing**:
    - Update `plugins/powerbi/agents/powerbi-developer.agent.md` to include `dax-unit-testing` and delegate DQV test generation to `pql-tester`.
    - Update `plugins/powerbi/skills/semantic-model-authoring/SKILL.md` to add a row in the Workflow Selector routing test requests to `dax-unit-testing`.
11. **Bake Registry-Driven Test Planning into the Architect Agent** (pytest parity, human-gated on expected values):
    - Update `plugins/powerbi/agents/powerbi-architect.agent.md`:
      - Add `dax-unit-testing` to the **Skills to use** list, described as the source of the certification-registry schema and assertion taxonomy used to plan test tasks (not to write DAX itself).
      - Add a **Guidelines** bullet describing a two-track task pattern per new/modified measure — not a single "test task" — reflecting that `Structural` tests need no business input while `Certification`/`Aggregation`/`Regression` tests do:
        1. A `sync` task (agent, automated) — delegate to `pql-tester` to generate and self-approve the measure's `Structural` row, and append a `Status=Pending` `Certification` placeholder row to `Certification/MeasureCertification.csv`.
        2. **Either** a **business-approval checkpoint** (human, blocking, non-agent) — flagged in the Tasks list as requiring the business/analyst owner to supply `FilterExpression`, `ExpectedValue`, `Owner`, `RequirementId`, and flip `Status` to `Approved` — **or**, if that value is already known at spec-authoring time (stated by the business owner during requirements gathering), fold it directly into the `sync` task: `pql-tester` writes the supplied value and sets `Status=Approved` in the same step, and this checkpoint task is skipped. The spec must make clear which of the two applies per measure.
        3. A `generate`+`run` task (agent, automated, gated on the `Certification` row reaching `Approved`, whether via step 2's checkpoint or the folded-in `sync`) — delegate to `pql-tester` to produce and execute the `.dax` file.
        Calculated columns and pure formatting/layout tasks are exempt from all three.
      - Add a one-time prerequisite rule: "If the spec's first measure task targets a model that does not yet have the PQL.Assert `functions.tmdl` library deployed, add a single setup task (deploy the assertion library) before the first `sync` task, rather than re-checking installation in every test task."
      - Update the **Spec Template**'s Tasks section guidance/example to show: optional one-time library-setup task → measure task → `sync` task → business-approval checkpoint (marked blocked/human-owned, omitted when the value was already folded into `sync`) → `generate`+`run` task. Add a line to the "Measures/Calculations" guidance under Components and Interfaces noting each measure entry should call out its planned test coverage and registry status.
    - This closes the gap where `pql-tester` exists but nothing in the spec-authoring step forces its use per measure — Phase 3 step 10 wires the *developer* side, this step wires the *planning* side that generates the tasks the developer executes, and correctly reflects that a `Certification`/`Aggregation`/`Regression` value can only be set `Approved` once a human has explicitly stated it — whether inline during planning or via a separate checkpoint — never invented by the agent itself; `Structural` coverage, needing no such value, is always agent-owned end-to-end.
    - **Applies going forward only**: this changes behavior for specs authored after the update; retrofitting test tasks into already-approved or in-flight specs is out of scope (see Scope & Boundaries).
12. **Update Root Agent System Prompts**:
    - Update `AGENTS.md` and `CLAUDE.md` to include `dax-unit-testing` and `pql-tester` in the skill and agent registries.

---

### Relevant Files

- `plugins/powerbi/skills/dax-unit-testing/SKILL.md` — Main skill documentation and execution workflows.
- `plugins/powerbi/skills/dax-unit-testing/references/functions.tmdl` — Reusable assertion library TMDL definition.
- `plugins/powerbi/skills/dax-unit-testing/references/model-independence.md` — Guidance for writing model-independent UDFs.
- `plugins/powerbi/skills/dax-unit-testing/references/reserved-dax-words.md` — Reserved word glossary.
- `plugins/powerbi/skills/dax-unit-testing/references/certification-registry-schema.md` — `MeasureCertification.csv` schema, lifecycle, and integrity-rule contract (GATE-001 §5).
- `plugins/powerbi/skills/dax-unit-testing/assets/scripts/validate_registry.py` — Registry integrity validator.
- `plugins/powerbi/skills/dax-unit-testing/assets/scripts/generate_measure_tests.py` — Approved-rows-to-`.dax` generator.
- `plugins/powerbi/skills/dax-unit-testing/assets/scripts/certify_measures.py` — Model scan/sync automation.
- `plugins/powerbi/skills/dax-unit-testing/assets/scripts/coverage_report.py` — Read-only test coverage statistics generator (`reports/coverage.json` + `reports/coverage-summary.md`).
- `plugins/powerbi/skills/dax-unit-testing/assets/RunPQLAssertTests.ipynb` — Fabric notebook runner asset.
- `plugins/powerbi/agents/pql-tester.agent.md` — Dedicated DAX Query View testing specialist agent (scan/sync/generate/run/report/diagnose).
- `plugins/powerbi/README.md` — Plugin documentation index.
- `plugins/powerbi/agents/powerbi-developer.agent.md` — Primary developer agent referencing the new test skill.
- `plugins/powerbi/agents/powerbi-architect.agent.md` — Spec-authoring agent updated to plan the sync → approval → generate/run task chain for every new/modified measure.
- `plugins/powerbi/skills/semantic-model-authoring/SKILL.md` — Routing table entry for semantic model testing.
- `AGENTS.md` and `CLAUDE.md` — Workspace agent configurations.

---

### Verification

1. **File & Asset Integrity**:
   - Verify all generated TMDL functions in `functions.tmdl` parse with valid indentation, tabs, and `annotation DAXLIB_PackageId = PQL.Assert`.
   - Verify `RunPQLAssertTests.ipynb` contains valid JSON and all cell execution outputs are blank.
2. **Agent & Skill Validation**:
   - Check YAML frontmatter on `pql-tester.agent.md` and `dax-unit-testing/SKILL.md` for proper syntax, descriptions, and tool definitions.
   - Confirm relative markdown links across docs resolve correctly.
   - Confirm `powerbi-architect.agent.md`'s Tasks-section guidance and example produce the `sync` → (business-approval checkpoint **or** folded-in approval) → `generate`+`run` pattern for a spot-check spec with a new measure — including a case where the business value is supplied inline (checkpoint correctly omitted) and a case where it isn't (checkpoint correctly present and marked non-agent/blocking) — and that calculated-column/layout-only tasks correctly get none of the three.
3. **Registry Contract Validation** (new):
   - Run `validate_registry.py` against valid, malformed, and quoted-comma-`FilterExpression` fixtures; confirm each documented rule (header match, `MeasureName`+`TestName` uniqueness, non-Structural non-empty `FilterExpression`, numeric `Tolerance >= 0`, no `Approved` row left at `TBD`) is caught and reported as `REGISTRY_INVALID`.
   - Run `generate_measure_tests.py` twice against identical fixture input and diff the output to confirm byte-identical, deterministic generation.
   - Hand-edit a generated `.dax` file and re-run generation; confirm it fails as `GENERATED_FILE_MODIFIED` instead of silently overwriting.
   - Confirm `certify_measures.py sync` auto-generates and self-approves the `Structural` row for a new measure, appends a `Status=Pending` `Certification` placeholder with `ExpectedValue`/`Owner`/`RequirementId` left blank/`TBD` when no value was supplied, and correctly writes those fields (and sets `Status=Approved`) only when a fixture simulates an explicit human-supplied value in the same call.
   - Run `coverage_report.py` against a fixture model + registry containing a mix of untested measures, `Pending` rows, and `Approved` `Structural`/`Certification` rows; confirm `reports/coverage.json` and `reports/coverage-summary.md` report the correct percentages, the correct `TestCategory` × `Status` breakdown, and list exactly the untested measures — and confirm the script makes no writes to the registry or model (read-only).
4. **Branch Guard Check**:
   - Run `check_git_branch_guard.txt` to ensure branch compliance on `feature/FIN-1787-glasslake-testing-framework`.
5. **Git Status & Conventions**:
   - Inspect `git status` and `git diff` to ensure clean additions matching repo style and conventions.

---

### Scope & Boundaries
- **In Scope**:
  - Integration of PQL.Assert 0.6.0 assertion functions and UDF library definitions into `powerbi-agentic-plugins`.
  - The `Certification/MeasureCertification.csv` schema reference and the four automation scripts (`validate_registry.py`, `generate_measure_tests.py`, `certify_measures.py`, `coverage_report.py`) as shared, reusable skill assets — the deterministic contract any target project's certification workflow (including a GATE-001-style gate) consumes.
  - Generating model-wide **test coverage statistics** for a semantic model (`coverage_report.py`, surfaced via `pql-tester`'s `report` mode) — a read-only snapshot of what fraction of measures have registry rows, at what `Status`, so gaps can be prioritized without re-deriving the numbers by hand.
  - Creation of the dedicated `pql-tester` agent (scan/sync/generate/run/report/diagnose) and `dax-unit-testing` skill.
  - Adding the Fabric batch test runner notebook to skill assets.
  - Updating all relevant registries, developer agents, and routing tables.
  - Updating `powerbi-architect.agent.md` so spec Tasks lists always plan the `sync` → (business-approval checkpoint or folded-in approval) → `generate`+`run` pattern for each new/modified measure task.
- **Out of Scope**:
  - Direct execution against live customer semantic models (e.g., Glasslake) — this task establishes the framework and tooling in the repository so agents and developers can author and execute those tests.
  - Modifying existing `dax-data-quality` (which handles Power Query-first row-level checks) — `dax-unit-testing` complements it by providing DAX Query View unit assertions.
  - Retrofitting test tasks into specs already drafted/approved before this plan lands — the architect's task-chain guideline applies only to specs authored after the update.
  - Implementing GATE-001's own CI/PR plumbing (`gate1-results.json`/`gate1.junit.xml`/`gate1-summary.md` publication, blocking-merge enforcement, environment rollout per its Phase 4–6) — that belongs to the target semantic model's own repo/pipeline, which consumes the scripts and error-type contract this plan ships. This plan is a dependency of GATE-001, not GATE-001 itself.
  - **Inventing** (as opposed to recording) `ExpectedValue`/`Owner`/`Status=Approved` for a `Certification`/`Aggregation`/`Regression` row on behalf of a business owner, at any point in this repo's tooling — the agent may write and self-approve such a row only when a human has explicitly supplied the value in the same request; it may never fabricate one. `Structural` rows are exempt from this restriction entirely since they carry no business judgment.
