# Migration Plan: Adopt skills-for-fabric-1 as Primary Base

> **Strategy shift:** Flip merge direction. `C:\Development\skills-for-fabric-1\plugins\powerbi-authoring\skills` becomes the **primary/base** architecture. The current repo (`powerbi-agentic-plugins/plugins/powerbi/skills`) is now the **donor** — only cost-effective, non-duplicated content gets grafted on top.

---

## TL;DR

The external `skills-for-fabric-1` powerbi-authoring plugin has a more mature, better-decomposed architecture: 6 skills with clean ownership boundaries (`check-updates`, `powerbi-report-authoring`, `powerbi-report-design`, `powerbi-report-management`, `powerbi-report-planning`, `semantic-model-authoring`), shared `common/*.md` references, and a Must/Prefer/Avoid + workflow-selector pattern throughout. The current repo already adopted this pattern for `powerbi-report-authoring` (per the prior `skill-merge.plan.md`) — this plan extends that same precedent to the remaining skills: replace `pbi-report-design` and `powerbi-semantic-model-authoring` with their external counterparts as the base, graft on only the current repo's unique/deeper content, import the 3 external skills the current repo is missing (`check-updates`, `powerbi-report-management`, `powerbi-report-planning`), and keep the current repo's skills that have no external counterpart (`dax-data-quality`, `sql-data-quality`, `tmdl`, `prep-powerbi-for-report-copilot`) untouched.

---

## Skill-by-Skill Inventory & Disposition

| External (skills-for-fabric-1) | Current (powerbi-agentic-plugins) | Disposition |
|---|---|---|
| `check-updates` | *(none)* | **Import wholesale** — new skill |
| `powerbi-report-authoring` | `powerbi-report-authoring` | **Already merged** — prior plan made external the base; verify no drift |
| `powerbi-report-design` | `pbi-report-design` | **Merge** — external becomes base; graft current's unique reference files |
| `powerbi-report-management` | *(none)* | **Import wholesale** — new skill (Fabric REST CRUD for report items) |
| `powerbi-report-planning` | *(none)* | **Import wholesale** — new skill (requirements → spec → approval → build) |
| `semantic-model-authoring` | `powerbi-semantic-model-authoring` | **Merge** — external becomes base; graft current's unique DAX reference files |
| *(none — lives in `fabric-consumption` plugin)* | — | Note dependency; do not port whole plugin, just note the gap |
| *(none)* | `dax-data-quality` | **Keep as-is** — no external counterpart |
| *(none)* | `sql-data-quality` | **Keep as-is** — no external counterpart |
| *(none)* | `tmdl` | **Keep as-is** — standalone TMDL editing skill with BOM-cleanup scripts; no external counterpart |
| *(none)* | `prep-powerbi-for-report-copilot` | **Keep as-is** — no external counterpart |
| *(none — no `agents/` in external plugin)* | `agents/pbip-validator.md`, `powerbi-architect.agent.md`, `powerbi-developer.agent.md` | **Keep as-is** — current repo's own persona layer; update skill-name references after merges |

**Confirmed infrastructure compatibility:** `powerbi-agentic-plugins/common/*.md` already contains `COMMON-CLI.md`, `COMMON-CORE.md`, `ITEM-DEFINITIONS-CORE.md`, etc. — matching the external plugin's shared reference folder. External skills that call `az rest` against these common docs will work unmodified in this repo.

---

## Skill-Creator Validation Results (objective, `quick_validate.py`)

Ran `skill-creator`'s frontmatter/structure validator (`plugins/skill-creator/skills/skill-creator/scripts/quick_validate.py`) against every skill in scope — current and external. This is a mechanical check (valid YAML, allowed frontmatter keys, kebab-case name, description rules), not a judgment call; failures below are facts, not opinions.

| Skill | Side | Result | Detail |
|---|---|---|---|
| `pbi-report-design` | Current | ❌ FAIL | Top-level `version: 26.25` key — not an allowed frontmatter property (must be nested under `metadata:`) and not semver |
| `powerbi-report-design` | External | ✅ PASS | `metadata.version: 0.1.0` |
| `powerbi-semantic-model-authoring` | Current | ✅ PASS | No `metadata.version` present |
| `semantic-model-authoring` | External | ✅ PASS | No `metadata.version` present |
| `powerbi-report-authoring` | Current | ✅ PASS | `metadata.version: 0.2.0` |
| `powerbi-report-authoring` | External | ✅ PASS | `metadata.version: 0.1.0` |
| `dax-data-quality` | Current (keep as-is) | ❌ FAIL | Top-level `version: 0.2.0` key — same misplacement bug as `pbi-report-design` |
| `sql-data-quality` | Current (keep as-is) | ❌ FAIL | Top-level `version: 0.1.0` key — same misplacement bug |
| `tmdl` | Current (keep as-is) | ✅ PASS | No `metadata.version` present |
| `prep-powerbi-for-report-copilot` | Current (keep as-is) | ✅ PASS | No `metadata.version` present |
| `check-updates` | External (import wholesale) | ✅ PASS | No `metadata.version` present |
| `powerbi-report-management` | External (import wholesale) | ✅ PASS | `metadata.version: 0.1.0` |
| `powerbi-report-planning` | External (import wholesale) | ✅ PASS | `metadata.version: 0.1.0` |

**Findings that change the plan:**
1. The `version:` top-level frontmatter bug is **not unique to the two merge candidates** — it also affects `dax-data-quality` and `sql-data-quality`, which this plan otherwise leaves untouched. Fixing it is a one-line, mechanical, zero-risk change and should be added to cleanup regardless of merge direction (see Phase 6 adjustment below).
2. Two external skills being adopted (`semantic-model-authoring` and `check-updates`) have **no `metadata.version` at all** — validation passes today because the rubric only penalizes a missing/invalid version, `quick_validate.py` doesn't require the field. Adopting them as-is would import that gap. Add `metadata.version: 0.1.0` to both during the wholesale-import/merge steps rather than treating "external passed validation" as "external is fully version-hygienic."

---

## Skill Quality Rating — 7-Dimension Rubric (1–5 scale, /35 total)

> Not an official Anthropic-published framework — see `plugins/powerbi/skills/skill-merge-planner/references/skill-quality-rubric.md` for dimension definitions and the "directional, not authoritative" caveat. Scores below fold in the validation findings above (e.g. a `quick_validate.py` frontmatter failure caps Description/Trigger Quality; a missing `metadata.version` caps Version Hygiene at 1 per the rubric's own definition).

### `powerbi-report-design` (external) vs `pbi-report-design` (current)

| Dimension | `pbi-report-design` (current) | `powerbi-report-design` (external) |
|---|---|---|
| Conciseness / context cost | 2 | 5 |
| Progressive disclosure | 2 | 5 |
| No duplication / scope boundary | 1 | 5 |
| Degrees-of-freedom matching | 1 | 5 |
| Description/trigger quality | 1 | 5 |
| No extraneous files | 4 | 5 |
| Version hygiene (semver) | 1 | 4 |
| **Total (/35)** | **12** | **34** |

**Reading the scores:** Not close — external has an explicit scope boundary, Must/Prefer/Avoid governance, a per-file "when to read" table, and clean frontmatter. Current's biggest liabilities are structural (phantom `pbip plugin` references to `pbir-cli`/`create-pbi-report`/`review-report`, none of which exist in this repo) and the malformed `version` key, not lack of content depth — this confirms the plan's "external as base" direction with no ambiguity, but strengthens the case that `pbi-report-design`'s unique reference files (`cards-and-kpis.md`, `tables-and-matrices.md`, `mobile.md`, `filter-pane.md`, `custom-visuals.md`, `tooltips-and-annotations.md`) are worth grafting precisely because they're the one thing the score doesn't capture (content depth).

### `semantic-model-authoring` (external) vs `powerbi-semantic-model-authoring` (current)

| Dimension | `powerbi-semantic-model-authoring` (current) | `semantic-model-authoring` (external) |
|---|---|---|
| Conciseness / context cost | 3 | 4 |
| Progressive disclosure | 2 | 5 |
| No duplication / scope boundary | 3 | 4 |
| Degrees-of-freedom matching | 3 | 5 |
| Description/trigger quality | 3 | 5 |
| No extraneous files | 4 | 5 |
| Version hygiene (semver) | 1 | 1 |
| **Total (/35)** | **19** | **29** |

**Reading the scores:** External still wins clearly (workflow-selector table, explicit tiered Tool Selection Priority, an explicit "Does NOT handle..." redirect), but the gap is narrower than the design pair — current's flat reference list and "Tool Selection Priority" section aren't bad, just less structured. Both sides score the minimum on Version Hygiene (neither has `metadata.version`) — this is the one dimension where "adopt external as base" does **not** automatically fix the problem; it must be added explicitly (see Skill-Creator Validation Results above).

---

## Detailed Merge Plans

### 1. `powerbi-report-design` ← `pbi-report-design` (external is base)

**External architecture to adopt as base:**
- 7-step structured workflow (Data-First Investigation → Design Identity → Archetype Router → Chart Selection → Visual Configuration → Theme → Canonical Design Contract)
- 5-archetype routing system (Executive Summary, Operational Monitor, Analytical Canvas, Narrative Story, Comparative Benchmark) with A/B/C layout variants per archetype
- Mandatory `Design Brief:` YAML contract with `layout_contract`, `space_audit`, `variant_rationale`
- Clean handoff boundary: never edits PBIR files, hands off to `powerbi-report-authoring`
- Must/Prefer/Avoid governance block
- Reference files (15): `archetype-composition.md`, `archetypes/*.md` (5 files), `brownfield.md`, `chart-selection.md`, `color.md`, `design-brief.md`, `interactivity.md`, `layout.md`, `pre-flight-checklist.md`, `signatures.md`, `tone-catalog.md`, `typography.md`, `visual-cookbook.md`, `accessibility.md`, `anti-patterns.md`

**Cost-effective additions to graft from current (`pbi-report-design`):**

| Current file | Why keep it | Action |
|---|---|---|
| `cards-and-kpis.md` | Deeper KPI/target/gap guidance than anything in external | Add as new reference file, cross-link from `visual-cookbook.md` |
| `tables-and-matrices.md` | Deeper table/matrix decision framework, sparklines, hierarchy design | Add as new reference file, cross-link from `visual-cookbook.md` |
| `mobile.md` | Phone-layout/`mobile.json` mechanics — no external equivalent | Add as new reference file |
| `filter-pane.md` | Lock/hide, card naming, Applied/Available styling — no external equivalent | Add as new reference file |
| `custom-visuals.md` | Build-vs-buy decision + routing to `deneb-visuals`/`svg-visuals`/`python-visuals` skills | Add as new reference file |
| `page-titles.md` | Title implementation + accessible wording — folds into external's layout/accessibility but has concrete recipe | Merge content into external's `layout.md` or keep standalone if distinct enough |
| `tooltips-and-annotations.md` | Report-page tooltip design, annotation primitives — no external equivalent | Add as new reference file |

**Do NOT bring over:** `page-shapes.md` (superseded by external's archetype system), `design-identity.md` (superseded by `tone-catalog.md` + `signatures.md`), `quality-gate.md` (superseded by `pre-flight-checklist.md`), `layout-guidelines.md` (superseded by `layout.md` — diff first for any unique content before discarding), `visual-colors.md` (superseded by `color.md` — diff first for any unique content before discarding).

**Structural fixes required regardless of source:**
- Remove all "pbip plugin" phantom references (both versions currently have variants of this problem)
- Fix version to semver (external is `0.1.0`; current is non-standard `26.25`)
- Replace external's "Update Check — ONCE PER SESSION (mandatory)" block with the explicit-only wording already applied to `powerbi-report-authoring/SKILL.md` in this repo — do not port the mandatory/first-use auto-trigger verbatim

### 2. `semantic-model-authoring` ← `powerbi-semantic-model-authoring` (external is base)

**External architecture to adopt as base:**
- Workflow-selector table routing user intent → named workflow section
- Tiered tool-selection priority (Tier 1: `powerbi-modeling-mcp` MCP > TMDL direct edit > `az rest` Fabric CLI)
- `az rest`-based Fabric REST API operations (relies on `common/COMMON-CLI.md`, `common/COMMON-CORE.md`, `common/ITEM-DEFINITIONS-CORE.md` — already present in this repo)
- Reference files (11): `connection-binding.md`, `dax-guidelines.md`, `dax-perf-decision-guide.md`, `dax-perf-patterns.md`, `direct-lake-guidelines.md`, `modeling-guidelines.md`, `naming-conventions.md`, `pbip.md`, `semantic-model-ai-readiness.md`, `semantic-model-rest-api.md`, `tmdl-guidelines.md`

**Cost-effective additions to graft from current (`powerbi-semantic-model-authoring`):**

| Current file | Why keep it | Action |
|---|---|---|
| `dax-udf-functions-guidelines.md` | DAX User-Defined Functions guide — no external equivalent | Add as new reference file, link from workflow-selector table |
| `dax-query-guidelines.md` | DAX query-writing guidance for validation — partially overlaps external's `semantic-model-consumption` skill (lives in a different plugin, `fabric-consumption`, not ported here) | Add as new reference file to avoid a cross-plugin dependency the current repo doesn't have installed |

**Do NOT bring over:** `dax-performance-optimization.md` (superseded by external's `dax-perf-decision-guide.md` + `dax-perf-patterns.md`, which is a more structured tiered framework — diff first for any unique optimization patterns before discarding), `TMDL.md` (superseded by `tmdl-guidelines.md` — diff first), `modeling-guidelines.md` / `direct-lake-guidelines.md` / `pbip.md` (external has same-named or equivalent files — diff for any project-specific customizations before discarding).

**Noted gap:** External's `semantic-model-consumption` skill (read-only DAX query workflows) lives in the `fabric-consumption` plugin, not `powerbi-authoring`. This repo does not currently install `fabric-consumption`. Either:
  (a) accept the gap and keep current's `dax-query-guidelines.md` as the local substitute, or
  (b) separately port `fabric-consumption/skills/semantic-model-consumption` in a follow-up.
  Recommend (a) for this pass to avoid scope creep.

**Structural fix required regardless of source:** External's `semantic-model-authoring/SKILL.md` also ships the mandatory "Update Check — ONCE PER SESSION" block (see its frontmatter). Replace with explicit-only wording, same as `powerbi-report-authoring/SKILL.md`, during Phase 4.

### 3. Import Wholesale: `check-updates`

Copy `C:\Development\skills-for-fabric-1\plugins\powerbi-authoring\skills\check-updates\` verbatim. This is the real, working update-check mechanism referenced (but missing) throughout the current repo's skills — resolves **Issue 3** from the original review (phantom check-updates references). Uses `~/.config/fabric-collection/last-update-check.json` as a weekly-cadence marker, comparing against GitHub releases.

**Follow-up:** Update the marketplace/repo identity strings inside `check-updates/SKILL.md` (it currently says "skills-for-fabric marketplace") to reference this repo's own release channel, or confirm the user wants to track upstream `skills-for-fabric` releases specifically. **User preference confirmed:** `check-updates` must only run when explicitly requested by the user ("check for updates", "is there a new version", "check-updates") — never automatically at session start or on first skill use. This repo already reflects that in `AGENTS.md` and `powerbi-report-authoring/SKILL.md`; apply the same explicit-only wording to the imported `check-updates/SKILL.md` itself if it ships any auto-trigger/cadence language implying it should run unprompted.

### 4. Import Wholesale: `powerbi-report-management`

Copy `C:\Development\skills-for-fabric-1\plugins\powerbi-authoring\skills\powerbi-report-management\` verbatim. Fills a real gap: current repo has no dedicated skill for Fabric REST CRUD on report items (create/get/update/delete/list report definitions) — that responsibility was previously blurred into `powerbi-report-authoring`. Uses `az rest` + `common/COMMON-CLI.md` (already present).

### 5. Import Wholesale: `powerbi-report-planning`

Copy `C:\Development\skills-for-fabric-1\plugins\powerbi-authoring\skills\powerbi-report-planning\` verbatim. Fills a real gap: current repo has no guided requirements → spec → approval → build workflow for net-new reports; `powerbi-developer.agent.md` currently does ad hoc spec creation inline. This skill formalizes that with a lockable `_brief/report-spec.md`.

**Follow-up:** Update `powerbi-developer.agent.md` and `powerbi-architect.agent.md` to route through this skill for "build me a dashboard"-style requests instead of improvising.

---

## Steps (Implementation Order)

### Phase 1 — Wholesale Imports (parallel, no dependencies)
1.1 Copy `check-updates/` into `plugins/powerbi/skills/`
1.2 Copy `powerbi-report-management/` into `plugins/powerbi/skills/`
1.3 Copy `powerbi-report-planning/` into `plugins/powerbi/skills/`

### Phase 2 — Verify Existing `powerbi-report-authoring` Alignment (independent)
2.1 Diff current `powerbi-report-authoring/SKILL.md` against external's latest version — confirm no drift since the original merge; the template/BPA-script additions from the prior merge plan should still be layered on top

### Phase 3 — Replace `pbi-report-design` with Merged `powerbi-report-design` (depends on nothing, but do after Phase 1 so `check-updates` exists to reference)
3.1 Copy external `powerbi-report-design/` wholesale into `plugins/powerbi/skills/powerbi-report-design/` (new folder)
3.2 Graft cost-effective reference files from old `pbi-report-design/references/`: `cards-and-kpis.md`, `tables-and-matrices.md`, `mobile.md`, `filter-pane.md`, `custom-visuals.md`, `tooltips-and-annotations.md`; diff `page-titles.md` for unique content and merge into `layout.md` if warranted
3.3 Add routing-table rows in `powerbi-report-design/SKILL.md` for each grafted reference
3.4 Diff `layout-guidelines.md` vs `layout.md` and `visual-colors.md` vs `color.md`; port any current-only content, then delete the superseded current files
3.5 Delete old `plugins/powerbi/skills/pbi-report-design/` folder once verified
3.6 Update all cross-references elsewhere in the repo (README.md, AGENTS.md, agent files) from `pbi-report-design` to `powerbi-report-design`

### Phase 4 — Replace `powerbi-semantic-model-authoring` with Merged `semantic-model-authoring` (depends on nothing, but do after Phase 1)
4.1 Copy external `semantic-model-authoring/` wholesale into `plugins/powerbi/skills/semantic-model-authoring/` (new folder)
4.2 Graft `dax-udf-functions-guidelines.md` and `dax-query-guidelines.md` from old `powerbi-semantic-model-authoring/references/`
4.3 Add rows in the new skill's workflow-selector/table-of-contents for both grafted files
4.4 Diff `dax-performance-optimization.md` vs `dax-perf-decision-guide.md` + `dax-perf-patterns.md`; port any unique patterns, then delete
4.5 Diff `TMDL.md` vs `tmdl-guidelines.md`, `modeling-guidelines.md`, `direct-lake-guidelines.md`, `pbip.md` for repo-specific customizations before discarding
4.6 Delete old `plugins/powerbi/skills/powerbi-semantic-model-authoring/` folder once verified
4.7 Update all cross-references (README.md, AGENTS.md, agent files, MCP tool priority docs) from `powerbi-semantic-model-authoring` to `semantic-model-authoring`

### Phase 5 — Update Repo-Level Wiring (depends on Phases 1, 3, 4)
5.1 Update `plugins/powerbi/README.md` skill list and descriptions
5.2 Update `AGENTS.md` skill references
5.3 Update `plugins/powerbi/agents/*.agent.md` to reference new skill names and route report-build requests through `powerbi-report-planning`
5.4 Update `c:\Users\IOURICHADOUR\.claude\CLAUDE.md` to match the final skill set (still needed regardless of merge direction — see original plan's Issue 2)
5.5 Keep `dax-data-quality`, `sql-data-quality`, `tmdl`, `prep-powerbi-for-report-copilot` untouched; only fix any internal links that pointed at renamed skills

### Phase 6 — Cleanup & Version Hygiene
6.1 Ensure every skill under `plugins/powerbi/skills/` has semver `metadata.version` — specifically add `metadata.version: 0.1.0` to `semantic-model-authoring` and `check-updates` after import, since the external source ships both without one (confirmed by `quick_validate.py`, see Skill-Creator Validation Results)
6.2 Fix the top-level `version:` frontmatter key (should be nested under `metadata:`) on `dax-data-quality` and `sql-data-quality` — same bug class as `pbi-report-design`, flagged by validation, and in scope even though both skills are otherwise untouched ("Keep as-is")
6.3 Remove any remaining "pbip plugin" phantom references repo-wide
6.4 Re-run the BPA/template verification from the original `skill-merge.plan.md` to confirm `powerbi-report-authoring` still passes after Phase 5 renames
6.5 Grep every imported/merged `SKILL.md` for "ONCE PER SESSION" / "mandatory" update-check language and rewrite to explicit-only (user preference, already applied to `AGENTS.md` and `powerbi-report-authoring/SKILL.md`)

---

## Verification

1. `plugins/powerbi/skills/` contains exactly: `check-updates`, `powerbi-report-authoring`, `powerbi-report-design`, `powerbi-report-management`, `powerbi-report-planning`, `semantic-model-authoring`, `dax-data-quality`, `sql-data-quality`, `tmdl`, `prep-powerbi-for-report-copilot` — no `pbi-report-design` or `powerbi-semantic-model-authoring` folders remain
2. `grep -r "pbip plugin"` across `plugins/powerbi/` → 0 matches
3. `grep -r "pbi-report-design\|powerbi-semantic-model-authoring"` across the repo (README, AGENTS.md, agents/) → 0 matches (all renamed)
4. Every grafted reference file is cross-linked from its new parent `SKILL.md` routing table
5. `grep -riE "ONCE PER SESSION|mandatory.*update.check"` across `plugins/powerbi/` → 0 matches (confirms no skill auto-triggers `check-updates`; it must only run when the user explicitly asks)
6. All `SKILL.md` files have `metadata.version` in semver format
7. Prior `powerbi-report-authoring` BPA script + template report still function (no regression from renames)
8. Re-run `plugins/skill-creator/skills/skill-creator/scripts/quick_validate.py` against every skill under `plugins/powerbi/skills/` → 0 `FAIL` results (confirms the `dax-data-quality`/`sql-data-quality` frontmatter fix and the merged skills' clean frontmatter)

---

## Decisions

### Decision 1: External-as-base direction
**Choice:** Adopt `skills-for-fabric-1` powerbi-authoring skills as the primary architecture going forward.
**Rationale:** More mature patterns (workflow selectors, tiered tool priority, Must/Prefer/Avoid governance, shared `common/*.md`), already partially adopted for `powerbi-report-authoring` in a prior merge — this plan just extends the precedent consistently.
**Alternative considered:** Keep current repo's versions as base and cherry-pick from external (rejected — inverts a decision already made for `powerbi-report-authoring`, would leave the plugin architecturally inconsistent).

### Decision 2: Wholesale import vs cherry-pick for new skills
**Choice:** Import `check-updates`, `powerbi-report-management`, `powerbi-report-planning` wholesale, unmodified.
**Rationale:** These fill genuine capability gaps with no current-repo equivalent to merge against; the current repo's `common/` folder already supports their `az rest` dependencies.
**Alternative considered:** Skip `powerbi-report-management`/`powerbi-report-planning` as out of scope (rejected — they resolve real architectural gaps the original review flagged, e.g., ad hoc spec creation in `powerbi-developer.agent.md`).

### Decision 3: `fabric-consumption` plugin boundary
**Choice:** Do not port the `fabric-consumption` plugin or its `semantic-model-consumption` skill in this pass; keep current's `dax-query-guidelines.md` as the local substitute.
**Rationale:** Avoids scope creep — this plan is scoped to the `powerbi` skill set, not the full Fabric plugin family.
**Alternative considered:** Port `fabric-consumption` too (deferred — flagged as a follow-up, not blocking this migration).

### Decision 4: Diff-before-delete for overlapping reference files
**Choice:** For files with a same-purpose external equivalent (`dax-performance-optimization.md`, `TMDL.md`, `modeling-guidelines.md`, `direct-lake-guidelines.md`, `pbip.md`, `layout-guidelines.md`, `visual-colors.md`), diff for repo-specific customizations before deleting the current-repo version.
**Rationale:** These may contain team-specific naming rules, BPA thresholds, or edits the user made "to adapt for our environment" per the original request — blind deletion risks losing that work.
**Alternative considered:** Delete immediately since external has a same-named file (rejected — too risky given the user explicitly said they adapted these files for their environment).

---

## Further Considerations

1. **User's own environment adaptations** — the user said they "made updates to adapt for our environment." Before deleting any current-repo file superseded by an external equivalent, diff line-by-line for environment-specific values (workspace names, naming conventions, BPA thresholds) and migrate those forward into the new base file.
2. **Agent file updates are non-trivial** — `powerbi-architect.agent.md` and `powerbi-developer.agent.md` reference skill names directly in prose; renames require careful find-and-replace plus a re-read of the agent's workflow logic (e.g., "Skills to use" list).
2a. **CLAUDE.md sync still required regardless of this new direction** — it must match whichever final skill names win.
3. **MCP tool priority reconciliation** — external `semantic-model-authoring` has a 3-tier priority (MCP > TMDL > `az rest`); confirm this matches or supersedes current repo's existing MCP-first guidance in `powerbi-developer.agent.md`.
4. **`.mcp.json` at plugin root** — external plugin ships its own `.mcp.json`; diff against current repo's `plugins/powerbi/.mcp.json` for any additional MCP servers before overwriting.
