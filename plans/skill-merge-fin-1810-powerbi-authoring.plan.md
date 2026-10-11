# Migration Plan: Keep Local `powerbi` Skills as Base, Selectively Graft from `skills-for-fabric\powerbi-authoring`

> **Strategy:** Local (`plugins/powerbi/skills`) becomes the base for every matched skill — it now scores higher or ties on the 7-dimension rubric across all 5 pairs — and the reference collection (`C:\Development\skills-for-fabric\plugins\powerbi-authoring\skills`) becomes a donor for a small number of specific, cost-effective additions only.

**Ticket:** FIN-1810 ("Merge updates from skills-for-fabric repo into Bayview"), branch `feature/FIN-1810-merge-skills-for-fabric-powerbi-authoring`
**Scope boundary:** This is a plan document only. No files were copied, deleted, or edited as part of producing it. Execution is a separate, explicit step to be approved per-phase.

---

## TL;DR

The reference collection (`skills-for-fabric\plugins\powerbi-authoring`) has aged relative to this repo's fork: it contains exactly the same 5 skill names as local (no reference-only skills, no capability gaps to import wholesale), and on 3 of 5 pairs its `SKILL.md` now references `scripts/`/`assets/` folders or companion skills (`fabriciq`) that don't actually exist in the current snapshot. Local wins the rubric on `powerbi-report-authoring` (31 vs 23), `powerbi-report-management` (28 vs 24), and `semantic-model-authoring` (31 vs 24), and is judged already-aligned/tied on `powerbi-report-design` (31 vs 30) and `powerbi-report-planning` (29 vs 29). Net outcome: **0 skills adopt reference as base, 3 skills get local-as-base selective text/resource changes, 2 skills are confirmed already-aligned with no file changes required, 0 wholesale imports, and 8 local-only skills are untouched.** The one genuinely valuable reference-only asset is `semantic-model-authoring/references/metadata-discovery.md`. Two phantom companion-skill redirects (`fabriciq`, `power-bi-custom-visuals`) must be stripped as part of the corresponding merges regardless of source.

**Note on prior art:** `plans/skill-merge.plan.md` (pre-existing) analyzed `powerbi-report-authoring` against an older reference path, `skills-for-fabric-1`, which **no longer exists on disk** — it was apparently replaced by the current `skills-for-fabric`. That plan recommended reference-as-base for `powerbi-report-authoring` on the strength of a `scripts/`/`assets/` bundle (BPA script, PBIR template) that **no longer ships** in the current reference snapshot. This plan supersedes that recommendation for `powerbi-report-authoring`: local is now the stronger and only-complete side.

---

## Skill-by-Skill Inventory & Disposition

| Reference | Local | Local /35 | Ref /35 | Confirmed disposition |
|---|---|---|---|---|
| `powerbi-report-authoring` | `powerbi-report-authoring` | 31 | 23 | **Merge, local as base** |
| `powerbi-report-design` | `powerbi-report-design` | 31 | 30 | **Already aligned** |
| `powerbi-report-management` | `powerbi-report-management` | 28 | 24 | **Merge, local as base** |
| `powerbi-report-planning` | `powerbi-report-planning` | 29 | 29 | **Already aligned** |
| `semantic-model-authoring` | `semantic-model-authoring` | 31 | 24 | **Merge, local as base** |
| *(none)* | `check-updates` | — | — | Keep as-is (local-only) |
| *(none)* | `dax-data-quality` | — | — | Keep as-is (local-only) |
| *(none)* | `dax-test-framework` | — | — | Keep as-is (local-only) |
| *(none)* | `dax-unit-testing` | — | — | Keep as-is (local-only) |
| *(none)* | `prep-powerbi-for-report-copilot` | — | — | Keep as-is (local-only) |
| *(none)* | `skill-merge-planner` | — | — | Keep as-is (local-only) |
| *(none)* | `sql-data-quality` | — | — | Keep as-is (local-only) |
| *(none)* | `tmdl` | — | — | Keep as-is (local-only) |

**Confirmed infrastructure compatibility:** No reference-only skills exist, so there is no wholesale-import phase and no new cross-repo dependency to wire in. All 5 matched pairs already share the same routing-table/reference-file architecture pattern, so grafted files slot into existing `references/` folders without structural changes.

### Resource inventory and proposed dispositions (Task 1.2)

The inventory below was run against the checked-out local skills and the current
`C:\Development\skills-for-fabric\plugins\powerbi-authoring\skills` snapshot on
2026-09-23. Counts include files below the named path; `SKILL.md` is listed
separately in the quality scorecard. These are recommendations pending the
task-1.3 user confirmation checkpoint.

| Matched skill | Local resources | Reference resources | Unique or unavailable dependency | Proposed disposition |
|---|---|---|---|---|
| `powerbi-report-authoring` | `references/`: 23 files; `scripts/`: `bpa-rules-report.json`, `bpa.ps1`, `report_reference_scan.ps1`, `report_reference_scan.py`, `tests/test_report_reference_scan.py`, plus one local `__pycache__` artifact; `assets/templateReport/**`: 72 template/report files | `references/`: the same 23 names; no `scripts/` or `assets/` | 78 local-only files; 12 same-named files differ (`card.md`, `cartesian.md`, `color-strategy.md`, `conditional-formatting.md`, `formatting.md`, `map.md`, `powerbi-desktop.md`, `re-theming.md`, `shape.md`, `slicers.md`, `table.md`, and `SKILL.md`); reference text does not have backing BPA, scan, or template resources | **Retain** all local scripts/assets and the local versions of shared files pending review; **diff** the 12 changed shared files before any replacement; **exclude/adapt** any reference prose that assumes unavailable scripts/assets |
| `powerbi-report-management` | No `references/`, `scripts/`, or `assets/` directory | No `references/`, `scripts/`, or `assets/` directory | Text-only pair; reference `SKILL.md` contains an unresolved `fabriciq` routing target | **Retain** local resource shape; **adapt/exclude** the phantom `fabriciq` redirect; any approved text graft is handled in `SKILL.md` only |
| `powerbi-report-planning` | No `references/`, `scripts/`, or `assets/` directory | No `references/`, `scripts/`, or `assets/` directory | Text-only pair; no resource dependency difference | **Retain** local resource shape; **diff** the two `SKILL.md` bodies only if task 1.3 approves a text change |
| `powerbi-report-design` | `assets/base.json`; 25 references, including local-only `cards-and-kpis.md`, `custom-visuals.md`, `filter-pane.md`, `mobile.md`, `tables-and-matrices.md`, and `tooltips-and-annotations.md` | The same `assets/base.json`; 19 references (no equivalent for the six local-only files) | Six local-only references are capability additions; five same-named references differ (`accessibility.md`, `anti-patterns.md`, `layout.md`, `visual-cookbook.md`, `archetypes/operational-monitor.md`); local `custom-visuals.md` points to unavailable `power-bi-custom-visuals` | **Retain** `assets/base.json` and all six local-only references; **diff** the five changed shared references before any replacement; **adapt/exclude** the unresolved custom-visual companion link |
| `semantic-model-authoring` | 13 references, including local-only `dax-query-guidelines.md` and `dax-udf-functions-guidelines.md`; `scripts/bpa-rules-semanticmodel.json`; `scripts/bpa.ps1` | 12 references, including reference-only `metadata-discovery.md`; no `scripts/` or `assets/` | Six same-named files differ (`modeling-guidelines.md`, `naming-conventions.md`, `pbip.md`, `semantic-model-ai-readiness.md`, `tmdl-guidelines.md`, and `SKILL.md`); reference `SKILL.md` contains an unresolved `fabriciq` routing target | **Retain** the two local DAX references and both BPA files; **graft** `references/metadata-discovery.md` after diffing for local terminology; **diff** the five changed shared references; **adapt/exclude** the phantom `fabriciq` redirect |

**Inventory closure:** There are no reference-only skill folders, no reference-only
scripts, and no reference-only assets. The only reference-only resource is
`semantic-model-authoring/references/metadata-discovery.md`. Every local-only
resource group is explicitly marked **retain**; every same-named content change is
marked **diff** before replacement; every unavailable dependency is marked
**adapt/exclude**; and the one proposed new resource is marked **graft**. The
local `__pycache__` file is a generated test artifact, not a migration candidate;
it remains local and is excluded from any merge copy operation. The user
confirmed all five matched-pair directions on 2026-09-23; the file-level
dispositions above are therefore approved subject to the companion-change gates
called out below.

## Ownership matrix and scenario coverage (Task 1.4)

The matrix uses one primary owner per request. Supporting skills or agents may be
delegated work, but they do not become a second primary owner.

| Concern or OpenSpec scenario | Primary owner | Supporting/delegated capability | Boundary that prevents overlap |
|---|---|---|---|
| Report pages, visuals, themes, filters, slicers, PBIR/PBIP formatting | `powerbi-report-authoring` | `powerbi-report-design` for an approved visual direction; `pbip-validator` for validation | Authoring owns local definition edits and rendering; management does not transport them |
| Fabric report item create/upload/download/update/list/delete or definition transport | `powerbi-report-management` | `fabric-cli`/Fabric REST transport | Management owns workspace CRUD and definition transport; authoring owns the file contents |
| Report requirements, audience, page plan, and build sequencing | `powerbi-report-planning` | `powerbi-report-design` and `powerbi-report-authoring` when the plan calls for them | Planning produces the implementation sequence; it does not edit report definitions |
| Open-ended visual identity, archetype, chart choice, layout, color, or accessibility design | `powerbi-report-design` | `powerbi-report-authoring` for implementation | Design decides the visual system; authoring writes PBIR/PBIP |
| Semantic-model tables, columns, measures, relationships, TMDL, saved DAX, refresh, or deployment | `semantic-model-authoring` | `tmdl`, `pbip-validator`, `dax-unit-testing`/`pql-tester` as applicable | Semantic-model authoring owns model changes; FabricIQ is read-only consumption |
| Natural-language insight/value from an existing Power BI report or model | `FabricIQ consumption` (only after its MCP and smoke-test gates pass) | Semantic-model metadata/query context | FabricIQ queries existing governed artifacts and never creates, edits, deploys, or deletes definitions |
| Cross-workload Fabric engineering request spanning multiple endpoints | `FabricDataEngineer` | Approved endpoint skills | The engineer remains the orchestrator and delegates endpoint implementation |
| Synapse, HDInsight, or Databricks migration | `FabricMigrationEngineer` | Approved migration/workload skills | The migration engineer owns assessment, phased plan, validation, and cutover orchestration |
| Main spec — “Report visual formatting request” | `powerbi-report-authoring` | `powerbi-report-design` only for design input | A visual/page/theme/filter/slicer change is not report CRUD or model editing |
| Main spec — “Fabric report publication request” | `powerbi-report-management` | Fabric REST/CLI transport | Publication is not report-layout authoring |
| Main spec — “Upstream content has no local dependency support” | `skill-merge-planner` / migration review | Owning Power BI skill | Broken upstream dependencies are adapted or excluded before import |
| Main spec — “Local report authoring resource is unique” | `powerbi-report-authoring` | `skill-merge-planner` for inventory evidence | Local scripts, templates, scanners, and references remain source-owned unless explicitly replaced |
| Main spec — “Matched skill pair is evaluated” | `skill-merge-planner` | `skill-creator` validator | Rubric and live validation guide but do not auto-select the base |
| Main spec — “Candidate contains a broken dependency” | `skill-merge-planner` / migration review | Owning Power BI skill | The unavailable companion/script/configuration is excluded or adapted |
| Main spec — “Business question over report data” | `FabricIQ consumption` (gated) | None until the capability is verified | No fallback to report authoring or management; unavailable FabricIQ is reported explicitly |
| Main spec — “FabricDataEngineer needs semantic-model work” | `FabricDataEngineer` | `semantic-model-authoring` | Data Engineer retains cross-workload ownership while delegating the model edit |
| Main spec — “Targeted report-planning request” | `powerbi-report-planning` | On-demand design/authoring references | Only planning and explicitly required references load |
| Main spec — “Installed skill references a local resource” | The selected source-owned Power BI skill package | Harness projection/install mechanism | Codex, Claude Code, and Copilot project the same body and resolve resources on demand |

**Scenario verification:** all ten scenarios in
`openspec/changes/merge-powerbi-and-fabric-data-engineering/specs/powerbi/authoring-skill-migration/spec.md`
are represented by exactly one `Main spec` row above. The additional concern
rows make the same ownership boundaries explicit for the companion FabricIQ and
data-engineering changes.

## Local Power BI capability-preservation inventory (Task 1.5)

The following source-owned paths were inventoried before any merge. The listed
decision applies to every file under each glob, including nested tests and
fixtures.

| Source path | Capability/resource | Preservation decision |
|---|---|---|
| `plugins/powerbi/skills/powerbi-report-authoring/assets/templateReport/**` | PBIP/PBIR/PBIX starter templates, dummy semantic model, themes, visuals, and template knowledge base | **Retain** unchanged; no upstream equivalent exists |
| `plugins/powerbi/skills/powerbi-report-authoring/scripts/bpa*` | Report BPA rules and runner | **Retain** unchanged |
| `plugins/powerbi/skills/powerbi-report-authoring/scripts/report_reference_scan.*` and `scripts/tests/**` | Power BI local report-reference scanner and tests | **Retain** unchanged; this remains the targeted report-term scanner |
| `plugins/powerbi/skills/powerbi-report-design/references/{cards-and-kpis,custom-visuals,filter-pane,mobile,tables-and-matrices,tooltips-and-annotations}.md` | Local visual-design coverage absent from the reference snapshot | **Retain**; adapt only the unavailable `power-bi-custom-visuals` link |
| `plugins/powerbi/skills/semantic-model-authoring/references/{dax-query-guidelines,dax-udf-functions-guidelines}.md` | Local DAX query/UDF guidance | **Retain** unchanged |
| `plugins/powerbi/skills/semantic-model-authoring/scripts/{bpa.ps1,bpa-rules-semanticmodel.json}` | Semantic-model BPA runner and rules | **Retain** unchanged |
| `plugins/powerbi/skills/dax-unit-testing/SKILL.md`, `references/**`, `assets/scripts/**`, `assets/templates/**`, `tests/**`, `evals/**`, `pyproject.toml`, `uv.lock`, `LICENSE-THIRD-PARTY.md` | PQL.Assert registry, certification lifecycle, generation scripts, templates, fixtures, and tests | **Retain** as the model/measure-testing capability; do not merge with row-level DQ skills |
| `plugins/powerbi/skills/dax-test-framework/SKILL.md`, `scripts/**`, `tests/**`, `assets/**`, `evals/**`, `pyproject.toml`, `uv.lock` | DEV Desktop/CLOUD XMLA transport, smoke gate, reports, dashboard, notebooks, samples, and tests | **Retain** as the execution capability; preserve its delegation boundary to `dax-unit-testing` |
| `plugins/powerbi/skills/dax-data-quality/**` | Power Query/DAX row-level data-quality rules, examples, references, and converter script | **Retain** independently; it tests data values, not semantic-model behavior |
| `plugins/powerbi/skills/sql-data-quality/**` | SQL audit-view data-quality rules, examples, references, and generators | **Retain** independently; no migration into measure testing |
| `plugins/powerbi/skills/prep-powerbi-for-report-copilot/**` | Copilot readiness guidance, docs, diagnostics, and AI-schema scripts | **Retain** as a local-only Copilot-preparation capability |
| `plugins/powerbi/skills/tmdl/**` | TMDL fallback guidance, examples, cleanup scripts, and BOM tools | **Retain** as a fallback authoring capability |
| `plugins/powerbi/skills/check-updates/SKILL.md` | Explicit marketplace/plugin update checking | **Retain**; exclude from upstream skill migration and do not invoke automatically |
| `plugins/powerbi/skills/skill-merge-planner/**` | Seven-dimension comparison rubric, merge-plan template, and eval inputs | **Retain** as migration governance; it is not a Power BI runtime capability |
| `plugins/powerbi/agents/{pbip-validator.md,powerbi-architect.agent.md,powerbi-developer.agent.md,pql-tester.agent.md}` | PBIP validation, architecture/planning, implementation, and DAX testing agents | **Retain**; update only routing boundaries approved by this change |
| `plugins/powerbi/README.md`, `plugins/powerbi/.mcp.json` | Power BI package catalog and MCP configuration | **Retain**; update only if approved routing or the metadata-discovery graft requires documentation |
| `plugins/powerbi/skills/paginated-report-authoring/tests/__pycache__/**` | Generated orphan test bytecode; no `SKILL.md` or installed capability | **Exclude** from migration/package inventory; do not treat this folder as a valid skill |

**Preservation verification:** every valid local-only Power BI skill, every
local report template/scanner/BPA resource, both DAX testing capabilities and
their tests/templates, all four Power BI agents, and package metadata have an
explicit path and preservation decision. The only directory without a valid
skill body is explicitly classified as generated output and excluded.

---

## Detailed Merge Plans

### 1. `powerbi-report-authoring` (local is base)

**Local architecture to adopt as base (unchanged):** existing routing table, CLI integrations (`powerbi-report-author`, `powerbi-desktop`), 30+ anti-pattern catalog, Must/Prefer/Avoid governance block, Edit→Validate→Reload→Screenshot loop, and the full `scripts/`+`assets/templateReport/` bundle (BPA script, BPA rules, PBIR starter report, dummy companion model).

**Cost-effective additions to graft from reference:**

| File | Why keep it | Action |
|---|---|---|
| *(none identified)* | Reference ships no `scripts/`/`assets/`, and all 22 same-named `references/*.md` files are near-identical in size/content to local's versions | No graft needed |

**Do NOT bring over:** Reference's `SKILL.md` body text describing BPA/template/dependency-scan tasks — it points to `scripts/bpa.ps1`, `scripts/bpa-rules-report.json`, `scripts/report_reference_scan.*`, and `assets/templateReport/**`, none of which exist in the current reference snapshot. Do not let any future sync re-introduce these as phantom references.

**Structural fixes required regardless of source:**
- None beyond periodic diffing of the 23 same-named reference files listed in the analysis (`card.md`, `conditional-formatting.md`, `formatting.md`, and `table.md` showed the most byte-size drift and are the first to line-diff if a sync is desired).

### 2. `powerbi-report-management` (local is base)

**Local architecture to adopt as base (unchanged):** existing routing table and Must/Prefer/Avoid governance; no `references/`/`scripts/`/`assets/` on either side — this is a SKILL.md-only skill.

**Cost-effective additions to graft from reference:**

| File | Why keep it | Action |
|---|---|---|
| *(no separate file — body text only)* | Reference has stronger telemetry-header guidance and richer publish-path/LRO (long-running operation) and duplicate-report-recovery troubleshooting language | Manually port the relevant paragraphs into local `SKILL.md`'s existing troubleshooting/telemetry sections; do not restructure the file |

**Do NOT bring over:** Reference frontmatter's `fabriciq` redirect for data-question routing — no such skill exists in either repo (see Decision 1).

**Structural fixes required regardless of source:**
- Confirm local `SKILL.md` has no equivalent phantom redirect before/after the text port.

### 3. `semantic-model-authoring` (local is base)

**Local architecture to adopt as base (unchanged):** existing routing table, delegation to `dax-unit-testing`/`pql-tester`/report-authoring, DAX query/UDF guideline refs, and the `scripts/bpa-rules-semanticmodel.json` + `scripts/bpa.ps1` bundle.

**Cost-effective additions to graft from reference:**

| File | Why keep it | Action |
|---|---|---|
| `references/metadata-discovery.md` (~7 KB) | Genuine reference-only addition: a dedicated metadata-discovery workflow not present locally | Copy into local `references/`, add a routing-table row in local `SKILL.md` pointing to it, and lightly edit for local terminology/CLI consistency |

**Do NOT bring over:** Reference frontmatter's `fabriciq` redirect (same phantom issue as `powerbi-report-management`, see Decision 1).

**Structural fixes required regardless of source:**
- After grafting `metadata-discovery.md`, verify no other local reference file already partially covers metadata discovery (avoid duplication) — the analysis found none, but confirm at merge time.

### 4. `powerbi-report-design` (already aligned — no merge required)

Architecture ties (31 vs 30). Local carries 6 extra local-only topic refs (`cards-and-kpis.md`, `custom-visuals.md`, `filter-pane.md`, `mobile.md`, `tables-and-matrices.md`, `tooltips-and-annotations.md`) with no reference counterpart — keep all six as-is. 19 same-named files are present; five resource files (`accessibility.md`, `anti-patterns.md`, `layout.md`, `visual-cookbook.md`, and `archetypes/operational-monitor.md`) show content drift and are optional low-priority diff targets, not automatic replacements.

**Structural fix required regardless of source:** local `custom-visuals.md` redirects to a `power-bi-custom-visuals` companion skill that doesn't exist in either repo (see Decision 1) — strip or rewrite that redirect independent of any reference-side merge.

### 5. `powerbi-report-planning` (already aligned — no merge required)

Tied rubric (29 vs 29), SKILL.md-only skill (no companion files on either side), functionally the same round-based planning workflow. No action required beyond periodic re-diff if either side changes.

### 6. Exclude: `fabriciq` companion-skill mechanism

Referenced only in the *reference* copies of `powerbi-report-management` and `semantic-model-authoring` frontmatter/body as a redirect target for data-question routing. Not imported: no `fabriciq` skill or file exists in either repo, and this repo has no equivalent capability to route to. If left in place after merging body text, it would become a phantom reference. Strip it during Phase 3 (Section 3.2/3.3 below) rather than porting it verbatim.

### 7. Exclude: Reference `powerbi-report-authoring`'s "periodic GitHub release check" language

The current reference `SKILL.md` body still describes a PBI Inspector download/update flow, but ships no backing `scripts/`/`assets/`. Not imported — this repo already has its own `check-updates` skill for explicit, repo-appropriate update checking, and importing reference's now-unbacked language would recreate a phantom reference.

---

## Steps (Implementation Order)

### Phase 1 — Wholesale Imports
*None required.* No reference-only skills exist to import.

### Phase 2 — Verify Already-Aligned Skills (independent, parallel-safe)
2.1 Diff `powerbi-report-design`'s 19 same-named reference files against the current reference copies; confirm the 4 flagged files (`accessibility.md`, `layout.md`, `operational-monitor.md`, `visual-cookbook.md`) have no reference-side improvement worth porting.
2.2 Diff `powerbi-report-planning`'s `SKILL.md` bodies line-by-line to confirm no drift beyond wording.
2.3 Strip/rewrite the phantom `power-bi-custom-visuals` redirect in local `powerbi-report-design/references/custom-visuals.md`.

### Phase 3 — Merge `powerbi-report-management` and `semantic-model-authoring` (parallel-safe, independent of each other)
3.1 For `powerbi-report-management`: port the telemetry-header and publish-path/LRO troubleshooting paragraphs from reference `SKILL.md` into local `SKILL.md`'s existing sections (no new files).
3.2 Strip the `fabriciq` redirect from the ported text; confirm no residual mention remains.
3.3 For `semantic-model-authoring`: copy `references/metadata-discovery.md` from reference into local `references/`.
3.4 Add a routing-table row in local `semantic-model-authoring/SKILL.md` pointing to the newly-grafted `metadata-discovery.md`.
3.5 Strip the `fabriciq` redirect from any ported reference text for this skill.
3.6 Bump `metadata.version` (semver patch/minor bump per repo convention) on both merged `SKILL.md` files.

### Phase 4 — Verify `powerbi-report-authoring` Requires No Merge Action
4.1 Confirm (already done in this plan's analysis) that reference ships no `scripts/`/`assets/` and no same-named reference file differs materially from local.
4.2 No file changes required for this skill under this plan; local stays exactly as-is.

### Phase 5 — Repo-Level Wiring & Cleanup
5.1 Update `plugins/powerbi/README.md` if the `metadata-discovery.md` addition changes the skill's documented capability list.
5.2 Confirm no repo-wide text (README, agent files) references `fabriciq` or `power-bi-custom-visuals` outside the two files fixed above.
5.3 Confirm all 5 merged/aligned skills have valid semver `metadata.version` after Phase 3's bumps.

---

## Verification

1. `plugins/powerbi/skills/` still contains exactly the same 14 skill folders — no new or removed folders (no wholesale imports in this plan).
2. `grep -r "fabriciq"` across `plugins/powerbi/skills/powerbi-report-management` and `plugins/powerbi/skills/semantic-model-authoring` → 0 matches after Phase 3.
3. `grep -r "power-bi-custom-visuals"` across `plugins/powerbi/skills/powerbi-report-design` → 0 matches after Phase 2.3.
4. `plugins/powerbi/skills/semantic-model-authoring/references/metadata-discovery.md` exists and is cross-linked from that skill's `SKILL.md` routing table.
5. All 5 matched skills' `SKILL.md` have `metadata.version` in valid semver format.
6. Existing BPA scripts (`powerbi-report-authoring/scripts/bpa.ps1`, `semantic-model-authoring/scripts/bpa.ps1`) still run unmodified — this plan does not touch either.

---

## Decisions

### Decision 1: Strip all phantom companion-skill redirects rather than importing/creating stub skills
**Choice:** Remove/rewrite `fabriciq` (2 occurrences, reference-side) and `power-bi-custom-visuals` (1 occurrence, local-side) redirects rather than treating them as capability gaps to fill.
**Rationale:** Neither companion skill exists in either repo; leaving them in place after a merge would create broken routing that agents following the SKILL.md would hit as a dead end. No user request indicated these companions should be built.
**Alternative considered:** Scaffold stub skills for `fabriciq`/`power-bi-custom-visuals` — rejected as out of scope for a merge-planning task; would require its own design/proposal.

### Decision 2: Treat the older `skills-for-fabric-1`-based `plans/skill-merge.plan.md` as superseded, not merged with this plan
**Choice:** This plan stands alone and does not attempt to reconcile line-by-line with the prior plan's recommendation (reference-as-base for `powerbi-report-authoring`).
**Rationale:** The prior plan's reference path (`skills-for-fabric-1`) no longer exists on disk; its `scripts/`/`assets/` inventory for reference-side `powerbi-report-authoring` is stale and does not reflect the current `skills-for-fabric` snapshot, which ships neither folder.
**Alternative considered:** Archive/delete `plans/skill-merge.plan.md` — deferred to the user; not done as part of this plan-only step.

### Decision 3: Use live UTF-8 `quick_validate.py` results as objective scoring evidence
**Choice:** Live validation was run on 2026-09-23 for all ten candidate folders with `PYTHONUTF8=1` and `py -3 plugins/skill-creator/skills/skill-creator/scripts/quick_validate.py <skill-folder>`; every candidate returned `Skill is valid!` with exit code 0.
**Rationale:** The Windows Python installation defaults to the `cp1252` codec, which raises `UnicodeDecodeError` for Unicode characters in the authoring and management skill bodies. That is an environment/validator invocation issue, not a structural candidate failure. UTF-8 mode gives the validator its intended file decoding behavior and produces the reproducible result used by this plan. The reference semantic-model skill's missing `metadata.version` remains a separate direct observation and caps Version hygiene at 2.
**Alternative considered:** Treat the default-codepage decode error as a candidate validation failure. Rejected because it occurs symmetrically before parsing either skill's frontmatter and disappears under the UTF-8 encoding expected for repository Markdown.

### Decision 4: User-confirmed base directions for all matched Power BI pairs
**Choice:** On 2026-09-23, the user confirmed the five directions recorded in the inventory: local-as-base merge for `powerbi-report-authoring`, `powerbi-report-management`, and `semantic-model-authoring`; already aligned for `powerbi-report-design` and `powerbi-report-planning`.
**Rationale:** This satisfies the required human review checkpoint. The rubric and inventory remain evidence for the decision, while the user confirmation controls the implementation direction.
**Alternative considered:** Proceed from rubric totals alone — rejected by the skill's review gate.

---

## Further Considerations

1. **`powerbi-report-management`'s Phase 3 merge is text-only** (no companion files), so it requires careful manual editing rather than a mechanical file copy — re-read the full merged section afterward for tone/structure consistency with the rest of local's `SKILL.md`.
2. **The 4 flagged `powerbi-report-design` files** (`accessibility.md`, `layout.md`, `operational-monitor.md`, `visual-cookbook.md`) showed byte-size drift but were not deep-diffed line-by-line in this pass — Phase 2.1 should do that diff before considering `powerbi-report-design` fully verified.
3. **This plan does not address** the local-only `skill-merge-planner-workspace/iteration-1` eval artifacts or the two previously-identified `skill-merge-planner` self-fixes (frontmatter description length, zero-functional-match guidance) noted in `plans/RESUME.md` §6 — those are a separate, already-scoped follow-up, not part of this ticket.
4. **No reference-only skill or mechanism required exclusion beyond the two phantom redirects and the stale PBI-Inspector update-check language** already covered in Decision 1 and the "Exclude" sections above.
5. **Task 2.4 preservation check:** all five matched skills pass live `quick_validate.py`, all local Markdown links under `plugins/powerbi/skills` resolve, and no installed Power BI skill retains `fabriciq`, `power-bi-custom-visuals`, the missing `pbip` skill path, or the old external template path. The pre-existing `skill-merge-planner` description-length failure remains a separate local-only follow-up and is not folded into this migration.

---

## Skill Quality Rating — Skill-Authoring Quality Rubric v1 (1–5 scale, /35 total)

> Not an official Anthropic-published framework — see `plugins/powerbi/skills/skill-merge-planner/references/skill-quality-rubric.md` for the caveat and dimension definitions. Live `quick_validate.py` results are recorded below; scores remain directional, and still require the user's disposition confirmation.

| Pair | Local validation | Reference validation |
|---|---|---|
| `powerbi-report-authoring` | Pass (exit 0) | Pass (exit 0) |
| `powerbi-report-management` | Pass (exit 0) | Pass (exit 0) |
| `powerbi-report-planning` | Pass (exit 0) | Pass (exit 0) |
| `powerbi-report-design` | Pass (exit 0) | Pass (exit 0) |
| `semantic-model-authoring` | Pass (exit 0) | Pass (exit 0) |

### `powerbi-report-authoring`

| Dimension | Local | Reference |
|---|---|---|
| Conciseness / context cost | 3 | 4 |
| Progressive disclosure | 4 | 3 |
| No duplication / boundary | 5 | 2 |
| Degrees-of-freedom matching | 5 | 4 |
| Description/trigger quality | 5 | 4 |
| No extraneous files | 4 | 3 |
| Version hygiene | 5 | 3 |
| **Total (/35)** | **31** | **23** |

### `powerbi-report-design`

| Dimension | Local | Reference |
|---|---|---|
| Conciseness / context cost | 4 | 4 |
| Progressive disclosure | 5 | 5 |
| No duplication / boundary | 4 | 5 |
| Degrees-of-freedom matching | 5 | 5 |
| Description/trigger quality | 4 | 4 |
| No extraneous files | 4 | 4 |
| Version hygiene | 5 | 3 |
| **Total (/35)** | **31** | **30** |

### `powerbi-report-management`

| Dimension | Local | Reference |
|---|---|---|
| Conciseness / context cost | 3 | 3 |
| Progressive disclosure | 4 | 4 |
| No duplication / boundary | 5 | 3 |
| Degrees-of-freedom matching | 4 | 5 |
| Description/trigger quality | 5 | 2 |
| No extraneous files | 4 | 4 |
| Version hygiene | 3 | 3 |
| **Total (/35)** | **28** | **24** |

### `powerbi-report-planning`

| Dimension | Local | Reference |
|---|---|---|
| Conciseness / context cost | 3 | 3 |
| Progressive disclosure | 5 | 5 |
| No duplication / boundary | 5 | 5 |
| Degrees-of-freedom matching | 5 | 5 |
| Description/trigger quality | 4 | 4 |
| No extraneous files | 4 | 4 |
| Version hygiene | 3 | 3 |
| **Total (/35)** | **29** | **29** |

### `semantic-model-authoring`

| Dimension | Local | Reference |
|---|---|---|
| Conciseness / context cost | 3 | 3 |
| Progressive disclosure | 4 | 5 |
| No duplication / boundary | 5 | 3 |
| Degrees-of-freedom matching | 5 | 5 |
| Description/trigger quality | 5 | 2 |
| No extraneous files | 4 | 4 |
| Version hygiene | 5 | 2 |
| **Total (/35)** | **31** | **24** |

**Reading the scores:** `powerbi-report-authoring`, `powerbi-report-management`, and `semantic-model-authoring` all show a clear, rubric-supported case for local-as-base — the gaps are driven mainly by reference-side phantom references (missing `scripts/`/`assets/`, `fabriciq` redirects) and missing `metadata.version`, not by local being architecturally weaker. `powerbi-report-design` and `powerbi-report-planning` are close enough (1-point and 0-point gaps) that "already aligned" is the correct call — the scores do not capture the small but real content differences (local's 6 extra design-topic refs, reference's `metadata-discovery.md`), which are handled separately in the file-inventory sections above.
