# Resume Notes: PQL.Assert / GATE-001 Integration Plan

> **Current handoff — 2026-09-29:** This top section supersedes older FIN-1810
> notes below where they conflict.

## FIN-1810 current handoff

- **Branch:** `feature/FIN-1810-merge-skills-for-fabric-powerbi-authoring`
- **Working tree:** the `RESUME.md` update is intentionally uncommitted; the
  branch itself is synchronized with `origin`.
- **Local commits not pushed:** none.
- **Latest commits:**
  - `a9850f9` — update the Windows Power BI Modeling MCP OpenSpec with the
    canonical `powerbi-modeling-mcp` name, transport-aware conflict handling,
    Windows x64 gating, bounded MCP initialization validation, and deterministic
    test requirements.
  - `ef767bf` — configure the FabricIQ MCP endpoint, required variant header,
    and Azure CLI token helper; mark the parent change's FabricIQ gate (task
    3.1) complete.
  - `5229821` — merge `DEV`, which brings the checked-in Codex agent-adapter
    model, collision preflight safeguards, the expanded installer integration
    suite, and paginated-report-authoring work.
- **Jira:** FIN-1810 remains In Progress. A plain-English comment was posted
  for `ef767bf` (comment `170942`). The required comment for merge `5229821`
  and the later `a9850f9` OpenSpec update were not posted in this session.

### Recorded verification

- `scripts/validate-codex-catalog.ps1` passed: 5 plugins, 31 skills, 7 agents,
  7 checked-in adapters, and 2 MCP definitions.
- `scripts/validate-fabric-capability-closure.ps1` passed.
- `scripts/test-setup-team-plugins.ps1 -RunIntegration` passed (exit code 0):
  isolated Codex and Copilot Fabric installation, `All`/`-Force`, collision,
  missing-adapter, stale-adapter, and one-target-failure paths. Codex registered
  both `fabric-mcp-server` and `FabricIQ` in its disposable profile.
- The merge resolution retained FIN-1810 routing: `powerbi-developer` now keeps
  FabricDataEngineer/FabricMigrationEngineer delegation and guarded FabricIQ
  routing, while also retaining paginated-report-authoring.
- Added checked-in adapters for `FabricDataEngineer` and
  `FabricMigrationEngineer`; they are required by the merged source-catalog
  parity validator.
- Strict validation passed for
  `fix-windows-powerbi-modeling-mcp`; it remains planning-only at **0/11 tasks
  complete**. Its implementation has not yet changed the repository setup
  script or source MCP declaration.
- The user-scoped Codex config was manually consolidated to one
  `powerbi-modeling-mcp` entry; the duplicate `powerbi-modeling` alias was
  removed, policies were preserved, and a backup was created at
  `C:\Users\IOURICHADOUR\.codex\config.toml.before-powerbi-modeling-mcp-20260929-100105.bak`.

### OpenSpec status and exact next work

- `merge-powerbi-and-fabric-data-engineering`: **15/18 tasks complete**.
  Remaining: 4.3 targeted authoring/management/planning/design/semantic-model/
  FabricIQ/data-engineering routing checks; 5.2 final reconciliation against
  companion changes; 5.3 final FIN-1810 Jira summary.
- `port-fabric-data-engineering-capabilities`: **13/17 tasks complete**;
  retain as active until its FabricIQ gate, routing tests, isolated
  multi-harness checks, and documentation tasks are completed.
- `add-fabriciq-consumption-skill`: archived on 2026-09-24 with all 14 tasks
  complete, including MCP contract, tool discovery, authorized smoke testing,
  skill routing, and documentation.
- `add-openspec-bridge-historical-backfill`: archived on 2026-09-14 with all
  14 tasks complete, including the Glasslake-1 dogfood run.
- `enable-local-vscode-dax-tests` and
  `add-python-powerbi-dependency-checking` remain unstarted (0/22 each).
- `adapt-plugins-and-agents-for-codex` was archived by the merged DEV work.

### Important current facts

- FabricIQ's current Codex configuration is
  `https://fabriciq.svc.cloud.microsoft/v1/mcp/fabriciq`, with header
  `X-VARIANTS: Fabric.Routing.FabricIQ.V1` and an Azure CLI authorization
  helper. The older `https://api.fabric.microsoft.com/v1/mcp/fabriciq` value
  in historical notes below is obsolete.
- Do not archive the FIN-1810 parent change yet: its last three tasks remain
  unchecked. Keep additional resume updates uncommitted unless a push is
  explicitly requested.

---

**Plan file:** [plan-pqlAssertIntegration.prompt.md](plan-pqlAssertIntegration.prompt.md)
**Ticket:** FIN-1787 ("Glasslake Testing Framework"), original working branch `feature/FIN-1787-glasslake-testing-framework` (the current checkout must be verified before implementation).
**Source spec reviewed (not in repo, was a chat attachment):** `GATE-001-measure-certification.prompt.md` — BI COE's "Measure Certification & Testing" gate. Re-attach it if a future session needs to re-verify section numbers (§5, §7, §8, §14 are cited throughout the plan).

This file tracks the PQL.Assert planning work, the separate dependency-checking OpenSpec change, and decisions that future implementation work must preserve.

---

## FIN-1810: Skills-for-Fabric migration (active)

**Ticket:** FIN-1810 — “Merge updates from skills-for-fabric repo into Bayview”
**Branch:** `feature/FIN-1810-merge-skills-for-fabric-powerbi-authoring`
**Latest commit:** `a9850f9` — `FIN-1810 update Windows Power BI MCP OpenSpec` (pushed to `origin`)
**Jira:** Assigned and In Progress; earlier planning-status comments exist, but no summary comment was posted for `a9850f9`.

### Decisions that must be preserved

- The main contract is [merge-powerbi-and-fabric-data-engineering](../openspec/changes/merge-powerbi-and-fabric-data-engineering), with two guarded companion changes: [add-fabriciq-consumption-skill](../openspec/changes/add-fabriciq-consumption-skill) and [port-fabric-data-engineering-capabilities](../openspec/changes/port-fabric-data-engineering-capabilities).
- Keep the local Power BI suite as the default base. The current `skills-for-fabric` snapshot is a selective donor, never a wholesale replacement; preserve local scripts, templates, report-reference scanning, DAX testing, skills, and agents unless an approved disposition says otherwise.
- Power BI ownership: report authoring owns PBIR/PBIP pages, visuals, formatting, templates, validation, rendering, and local reference scanning; report management owns Fabric report CRUD/definition transport; planning owns requirements/sequencing; design owns open-ended visual design; semantic-model authoring owns model changes and saved DAX.
- FabricIQ is additive and uses the verified endpoint `https://fabriciq.svc.cloud.microsoft/v1/mcp/fabriciq`, alongside the existing Fabric MCP server. Do not add a report-management or semantic-model FabricIQ redirect until its companion change has completed its configuration, `tools/list`, and smoke-test gates.
- Scope the Fabric import to `FabricDataEngineer`, root-level `FabricMigrationEngineer`, and their declared skill closure only. Do not import FabricAdmin, FabricAppDev, FabricIQ persona, or unrelated Fabric skills.
- Codex, Claude Code, and GitHub Copilot CLI must discover one shared source-owned skill body. Preserve progressive disclosure: routing metadata first, selected `SKILL.md` on trigger, and references/scripts/assets only when selected by the workflow.
- Before merging any matched Power BI pair, run `skill-merge-planner`'s seven-dimension rubric and live `quick_validate.py` on both candidates, inventory references/scripts/assets, and obtain a user-confirmed disposition. Rubric totals guide the decision but never make it automatically.

### Resume point

1. Tasks 1.1 and 1.2 are complete: all ten candidate skill folders pass live `quick_validate.py` in UTF-8 mode, and the plan records the exact local/reference resource inventory, unique resources, unavailable dependencies, and proposed retain/graft/diff/exclude/adapt dispositions. The validator's default Windows codepage cannot decode Unicode in two pairs; use this PowerShell pattern (pass a **skill folder**, not `SKILL.md`) and do not record the symmetric decode error as a candidate defect:

   ```powershell
   $env:PYTHONUTF8 = '1'
   py -3 plugins/skill-creator/skills/skill-creator/scripts/quick_validate.py plugins/powerbi/skills/<skill>
   py -3 plugins/skill-creator/skills/skill-creator/scripts/quick_validate.py C:\Development\skills-for-fabric\plugins\powerbi-authoring\skills\<skill>
   ```
2. Tasks 1.3–1.5 are complete: the user confirmed all five matched-pair directions; the plan records the one-owner-per-scenario matrix and the path-based local capability-preservation inventory.
3. Tasks 2.1–2.4 are complete: report-management routing/telemetry was updated, semantic-model metadata discovery was grafted, the design phantom redirect was adapted, local reference paths were repaired, and all five matched skills plus all local Markdown links passed their scoped checks. The pre-existing `skill-merge-planner` description-length validator failure remains a separate follow-up.
4. The `add-fabriciq-consumption-skill` companion is archived complete. The
  remaining FIN-1810 work is the parent change's targeted routing checks and
  reconciliation, plus the selected Fabric capability's routing, targeted
  tests, isolated multi-harness checks, and documentation tasks.
5. Keep this resume update uncommitted unless a push is explicitly requested;
  post a Jira summary only when asked or after a subsequent commit per the
  Jira workflow.

### Implementation update — 2026-09-24

- The selected Fabric data-engineering closure is now ported under
  `plugins/fabric`: `spark-cli`, `sqldw-cli`, `eventhouse-cli`, `eventstream-cli`,
  `dataflows-cli`, `e2e-medallion-architecture`, `synapse-migration`,
  `hdinsight-migration`, and `databricks-migration`.
- `FabricDataEngineer` was imported and a local `FabricMigrationEngineer`
  orchestration adapter was authored because the current upstream snapshot does
  not contain the named migration-agent file.
- Shared closure metadata is recorded in `plugins/fabric/capability-closure.json`
  and checked by `scripts/validate-fabric-capability-closure.ps1`.
- Codex projection copies checked-in `.toml` agent adapters paired with source
  `.agent.md` instructions. Isolated Codex and Copilot Fabric projections
  passed discovery/content checks.
- The FabricIQ MCP endpoint and six-tool contract are configured and the
  authorized read-only smoke gates passed in the archived companion change.
  The parent and Fabric capability changes still retain their explicit routing
  and final-reconciliation tasks until those implementation checks are closed.

### `add-fabriciq-consumption-skill` — archived complete

- The archived configuration uses the verified endpoint
  `https://fabriciq.svc.cloud.microsoft/v1/mcp/fabriciq`.
- The installed-plugin probe reloaded successfully, exposed all six required
  `FabricIQ-*` tools, and completed authorized discovery and read-only smoke
  coverage without authentication or transport errors.
- The repository skill records the exact tool mappings, source-bound workflow,
  governance rules, routing boundaries, and unavailable-capability handling.
- The skill frontmatter passed `quick_validate.py` via
  `uv run --no-project python`.

---

## 1. Completed planning work

- [OpenSpec change](../openspec/changes/archive/2026-09-10-integrate-pql-assert-dax-testing) is implemented and archived. Its completed artifacts passed strict validation and include `proposal.md`, `design.md`, `tasks.md`, and three capability specs: `powerbi/dax-unit-testing`, `powerbi/pql-tester-agent`, and `powerbi/architect-test-planning`.
- Full GATE-001 CSV registry model is planned: `Certification/MeasureCertification.csv` schema reference, four automation scripts (`validate_registry.py`, `generate_measure_tests.py`, `certify_measures.py`, `coverage_report.py`), registry-driven `SKILL.md` workflow, model-wide coverage statistics, and the fixed error-type vocabulary.
- `pql-tester.agent.md` is planned with the full mode set (`scan`/`sync`/`generate`/`run`/`report`/`diagnose`), DEV/CLOUD execution, a restricted write scope, and no-silent-failure-suppression guardrails.
- `powerbi-architect.agent.md` is planned to include the progressive measure-testing chain: `sync` (automated Structural coverage) → developer certification of an explicit, reproducible baseline → `generate`+`run`; business certification is an optional additive step, never a blocking prerequisite.
- One-time prerequisite rule for deploying `functions.tmdl` before the first `sync` task.
- Verification includes registry-integrity fixtures, idempotent generation, content-hash tamper detection, sync behavior, coverage-report statistics, branch guard, and strict OpenSpec validation.
- GATE-001's CI/PR plumbing (JUnit publication, PR comments, blocking-merge rollout) remains explicitly **out of scope**. This work supplies reusable tooling that a target semantic model project's gate consumes.

## 2. Decisions recorded

### 2a. DECIDED AGAINST — do not mirror/reuse the DQ skills' files or structure for `dax-unit-testing`

An earlier recommendation (this session) proposed mirroring `dax-data-quality`/`sql-data-quality`'s file layout and approval-gate UX for `dax-unit-testing` — e.g. an `interaction-playbook.md` and `examples/*.csv` styled after theirs, cross-linked to their docs. **Rejected.** Decision: keep `dax-unit-testing` fully independent from `dax-data-quality`/`sql-data-quality` — no shared/mirrored reference files, no cross-linking between the skills' docs, no styling `dax-unit-testing`'s SKILL.md or registry docs after theirs. Rationale: per §2b below, the two are testing fundamentally different things (model/measure logic vs. row-level data values); making their file layout or wording look like variations of the same pattern risks users conflating a data-quality exception with a broken measure/relationship, or assuming the two registries (`MeasureCertification.csv` vs `dq_rules.csv`) are interchangeable or migrate the same way. `dax-unit-testing`'s own `SKILL.md`, `references/`, and any registry-workflow documentation should be authored on their own terms, informed only by GATE-001 and the PQL.Assert framework — not by the DQ skills' conventions.

The PowerShell-vs-Python scripting-language point still stands on its own merits (Python for `dax-unit-testing`'s scripts is justified by shared fixtures/CLOUD-XMLA connectivity with the existing Python DAX Test Framework and notebook runner) but should be explained from that rationale alone, not framed as a divergence from the DQ skills.

### 2b. Clarify scope: `dax-unit-testing` tests the model, DQ skills test the data

User correction, important and correct: `dax-data-quality`/`sql-data-quality` validate **data** (row-level field values — blanks, duplicates, domain/range violations, referential integrity via `RuleType`: `KeyNotBlank/KeyUnique/TypeNumber/TypeDate/Range/Domain/RI`). `dax-unit-testing` (PQL.Assert) validates the **model** — DAX logic, relationships, partitions, perspectives, OLS, and measure behavior under specific filter contexts (`TestCategory`: `Structural/Certification/Aggregation/Regression`, plus the broader assertion taxonomy: Relationship, Partition, Perspective, OLS, Best Practice). A model can be logically perfect and still fail every DQ check (dirty source data), or pass every DQ check and still have a broken measure/relationship. These are orthogonal axes, not overlapping ones — the CSV+approval-gate *mechanism* is reusable UX, but `MeasureCertification.csv` is not a same-shape rename of `dq_rules.csv`.

Implementation must preserve this boundary: `dax-unit-testing`'s assertion taxonomy is broader than the `MeasureCertification.csv` registry. Relationship/Partition/Perspective/OLS/Best-Practice assertions are structural, agent-verifiable checks that do not need developer or business certification and may later back a GATE-002-style semantic-model-governance gate. `Certification`/`Aggregation`/`Regression` measure-value tests use the progressive registry path: `Pending` → developer-approved executable baseline and, optionally, additive business certification.

Keep this distinction explicit in the skill documentation: `dax-data-quality`/`sql-data-quality` test data; `dax-unit-testing` tests model behavior. Their registries are neither interchangeable nor migration-compatible.

### 2c. DECIDED — progressive certification replaces a blocking business checkpoint

The original plan's mandatory business-approval checkpoint was replaced in the OpenSpec change. A developer can explicitly certify an observed, reproducible baseline and make it executable immediately; the row records `Status=Approved`, `ApprovalSource=Developer`, `ApprovedBy`, and `ApprovedOn`. `Structural` rows use `ApprovalSource=Structural` and remain fully automated. Later business-owned checks are additive rows or certifications recorded as `ApprovalSource=Business`; they do not block `sync`, generation, or execution of the developer baseline.

`ApprovalSource` is intentionally separate from `Status`: `Status=Approved` means eligible for generation/execution, not necessarily business-signed-off. Coverage reporting must independently show Structural, developer-certified, and business-certified coverage rather than collapsing them into one percentage.

## 3. Separate Power BI dependency-checking change

- [OpenSpec change](../openspec/changes/add-python-powerbi-dependency-checking) is planned and passes `openspec validate --strict --changes "add-python-powerbi-dependency-checking"`; implementation tasks remain unchecked. It contains the proposal, design, tasks, and a new `powerbi/dependency-checking` capability spec.
- It adds a standalone `powerbi-dependency-checking` skill, not a subfeature of `dax-unit-testing`. The planned Python static scanner analyzes local PBIP/TMDL/PBIR source offline, builds a typed dependency graph, supports impact queries, identifies potentially unused objects, and returns stable human-readable/JSON/quiet outputs suitable for CI.
- The design is informed by ripbi's local-PBIP static-analysis approach but implements an independent Python tool, rather than vendoring or requiring ripbi's Rust binary.
- Route architecture, semantic-model authoring, report authoring, and DAX-unit-testing workflows to it before rename/removal, dependency-sensitive changes, or test-coverage impact review. Findings are advisory evidence only; the tool never changes PBIP source or deletes objects.
- Keep the existing `powerbi-report-authoring` report-term scanner unchanged. It serves targeted raw-text searches; dependency checking provides the complete cross-model graph.

## 4. Next steps when resuming

1. Before changing files, verify the checkout and branch match the intended
  work. The current checkout is the FIN-1810 feature branch, not the historical
  FIN-1787 or `DEV` context recorded below.
2. For dependency checking, use the OpenSpec apply workflow for
  `add-python-powerbi-dependency-checking` and follow its task order.
3. Treat the archived PQL.Assert change as completed; use its artifacts as implementation reference rather than attempting to apply it again.
4. Preserve §§2a-2c for any PQL.Assert follow-up and §3's standalone ownership boundary for dependency checking.
5. Do not add an `interaction-playbook.md`/`examples/` pair modeled after the DQ skills; any future supporting files for `dax-unit-testing` must be independently authored.
6. `plan-skillMigrationReview.prompt.md` remains an unrelated migration plan and was not touched by this work.

## 5. Other pending work: `spec-lifecycle` plugin and historical backfill workflow

Not part of the PQL.Assert/GATE-001 plan above — developed separately on the same
`feature/FIN-1787-glasslake-testing-framework` branch and noted here only because this is the
repo's shared `RESUME.md`.

- New plugin: [plugins/spec-lifecycle](../plugins/spec-lifecycle) — one skill
  (`openspec-bridge`), no agent. It bridges an existing `powerbi-architect`
  `specs/<Name>.spec.md` into OpenSpec artifacts and archive history without changing how the
  source spec is authored.
- The bridge now has a deliberately narrow two-outcome rule: **Backfill now** for a completed,
  stable, unarchived spec; **Skip** for work still in progress or work the user does not want
  tracked. It does not leave an ongoing OpenSpec change open alongside an actively edited
  `spec.md`.
- The backfill workflow maps the source into `proposal.md`, the delta spec, `design.md`, and a
  fully checked `tasks.md`, then hands off to `openspec-archive-change` so delta sync and
  date-prefixed archive naming follow the repository contract.
- The planning change is archived at
  [2026-09-14-add-openspec-bridge-historical-backfill](../openspec/changes/archive/2026-09-14-add-openspec-bridge-historical-backfill)
  and its archived artifacts passed strict validation.
- Fully additive: it does not touch `plugins/powerbi/*`, so `check-updates`/
  `skill-merge-planner` diffs against the upstream `skills-for-fabric` marketplace stay
  unaffected.
- Registered in `.claude-plugin/marketplace.json` and the top-level `README.md` plugin table.
- Installed and dogfooded via `setup-team-plugins.ps1 -PluginName spec-lifecycle` against
  Glasslake-1's `specs/Python-MCP-DAX-Test-Framework.spec.md`; the resulting change was archived
  with synced specs and the source spec remained intact apart from its tracking pointer.

## 6. Unrelated addition this session: `skill-merge-planner` scored via `skill-creator`'s eval loop

Also unrelated to the PQL.Assert/GATE-001 work above — a separate `/skill-creator` invocation to
evaluate and score `plugins/powerbi/skills/skill-merge-planner`. Noted here only because it's the
repo's only `RESUME.md`.

- Ran `quick_validate.py` (from the sibling `skill-creator` skill) against `skill-merge-planner`'s
  `SKILL.md`: **fails** — frontmatter `description` is 1144 chars, over the 1024-char limit. This
  is an objective defect independent of behavior; not yet fixed.
- Ran the full with-skill vs. no-skill baseline eval loop (2 test cases from the skill's existing
  `evals/evals.json`, graded against their existing `expectations`). Results saved under
  `plugins/powerbi/skills/skill-merge-planner-workspace/iteration-1/` (`benchmark.json`/`.md`,
  per-eval `grading.json`, and a static `review.html` viewer already generated and opened).
  - **With-skill: 90% pass rate. No-skill baseline: 100% pass rate** (skill currently *underperforms*
    a plain agent on one of the two test cases).
  - Eval 1 (explicit reference path pointing at `skill-creator`, which has no Power BI counterpart):
    with-skill scored 4/5 — it correctly found zero functionally-matched skill pairs but then, per
    Step 4's literal wording ("score every compared pair"), left the entire 7-dimension rubric table
    `N/A` instead of scoring anything. The baseline agent, unconstrained by that wording, used
    judgment to benchmark the nearest adjacent pair anyway (`skill-merge-planner` 32/35 vs.
    `skill-creator` 23/35) and produced a materially more complete, more useful plan from the same
    input.
  - Eval 2 (missing default sibling reference path): both configurations handled it identically and
    correctly (detected the missing path, refused to fabricate results, asked for the right input,
    preserved the plan-only scope). Non-discriminating — keep as a regression guard, not as primary
    evidence of skill value.
  - Both configurations respected the read-only/plan-only scope boundary in every run — no repo
    files were touched (verified via `git status`).
- **Two fixes identified but not yet applied** (paused for user confirmation before proceeding):
  1. Trim the frontmatter `description` under 1024 chars.
  2. Add guidance to Step 2/4 for the zero-functional-match case: still offer an architecture-only
     benchmark of the nearest adjacent skill for informational value, rather than leaving the rubric
     table empty.
- Next step if resuming this thread: apply the two fixes above, bump `metadata.version`, re-run the
  same 2-eval loop into `iteration-2/` (with `--previous-workspace iteration-1`), and confirm the
  with-skill pass rate closes the gap with (or exceeds) the 100% baseline.

## FIN-1810 implementation checkpoint — historical snapshot, 2026-09-24

- **Committed scope:** the selected Fabric data-engineering closure, FabricDataEngineer,
  local FabricMigrationEngineer adapter, closure metadata/validator, Codex agent-adapter
  generation, Power BI/Fabric ownership guidance, and catalog validation fixes.
- **Verification:** strict OpenSpec validation passed; all selected Fabric skills passed
  `quick_validate.py`; the source catalog and Fabric closure validators passed; isolated Codex
  projection passed with 11 skills, 2 agents, and Fabric/FabricIQ MCP registration; isolated
  Copilot projection passed with the selected Fabric skills and agents.
- **Superseded:** the FabricIQ companion was subsequently archived after its
  authorized tool and smoke-test gates passed. The current next actions are
  the remaining parent and Fabric capability routing/reconciliation tasks listed
  in the current handoff above.
