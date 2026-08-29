---
name: skill-merge-planner
description: >-
  Compares this repo's plugin skills against an external/reference skill
  collection (e.g. skills-for-fabric-1's powerbi-authoring plugin), scores each
  matched skill pair against a 7-dimension Skill-authoring quality rubric,
  identifies cost-effective content to graft from either side, and generates a
  structured merge/migration plan saved under plans/<name>.plan.md. Use when
  the user wants to: (1) check whether local skills have drifted from an
  upstream/reference skill collection, (2) rate skill authoring quality
  (conciseness, progressive disclosure, duplication, degrees-of-freedom,
  description quality, version hygiene), (3) decide which skill should become
  the "base" in a merge, (4) produce a phased implementation plan before
  actually copying/merging files. Does NOT check plugin version numbers or
  marketplace releases — this repo tracks skills as a maintained fork, not a
  marketplace subscriber; use a dedicated update-check mechanism for that if
  one is ever wired up. Triggers: "compare skills to upstream", "generate
  merge plan", "check skill drift", "rate skill quality vs external", "should
  we adopt X as base", "sync skills plan".
metadata:
  version: 0.2.0
---

# Skill Merge Planner

Compares plugin skills in this repo against an external reference skill collection, rates architectural quality on both sides, and produces a durable, phased merge plan — the same workflow used to produce `plans/skill-merge.plan.md` and the powerbi-authoring migration plan in this session.

**Scope boundary** — This skill produces a *plan document*. It does not copy files, delete folders, or edit cross-references itself; execution of the resulting plan is a separate, explicit step the user approves per-phase.

## Must/Prefer/Avoid

### MUST

- Read both `SKILL.md` files (full frontmatter + body) for every compared pair before scoring or recommending a merge direction.
- List `references/`, `scripts/`, and `assets/` folder contents on **both** sides before claiming a file "has no equivalent."
- Score every compared pair against all 7 dimensions in [`references/skill-quality-rubric.md`](references/skill-quality-rubric.md) before recommending a base direction — never decide direction from content depth alone.
- Before finalizing any score, run the `skill-creator` skill's objective validator (`plugins/skill-creator/skills/skill-creator/scripts/quick_validate.py`) against every candidate `SKILL.md` — see Step 4. A validation failure is a hard fact, not a rubric hunch; fold it into the relevant dimension rather than eyeballing frontmatter by hand.
- Present the full score table (rubric + validation results) to the user and get explicit confirmation of the recommended base direction for every skill pair (Step 5) before drafting the final plan document (Step 7). Rubric totals are a recommendation the user can override, not an automatic decision.
- Save the final plan as a real file under `plans/<slug>.plan.md`. A plan that only exists in chat or session memory is not done.
- Explicitly call out and exclude any external mechanism that doesn't apply to this repo (e.g., a marketplace-specific update-check skill) rather than importing it silently.

### PREFER

- Match skills by **function**, not literal folder name (e.g. current `pbi-report-design` vs external `powerbi-report-design` are the same concern despite the name difference — record the mapping explicitly).
- List per-file "cost-effective addition" candidates (current-only files with no external equivalent, or with materially deeper content) separately from the architecture-quality rating — these are two different questions.
- Phase the resulting plan (wholesale imports → merges → repo-wide wiring updates → cleanup/version hygiene) so it can be executed incrementally and safely.
- Cross-check for phantom references — skills that mention companion skills/plugins that don't actually exist in either repo.
- Diff-before-delete for any current-repo file that has a same-named external equivalent; the user may have adapted it for their environment.
- For a skill pair the user calls out as high-stakes (contested base direction, a skill with bundled scripts, or a security/RLS-adjacent skill), offer skill-creator's full behavioral eval loop (test prompts run through both candidate skills, graded against assertions, compared in the benchmark viewer) as a deeper alternative to the static rubric — see Step 4.

### AVOID

- Do not assume "external" is automatically the base — only recommend it when the rubric scores support it for that specific skill. Direction can differ per skill.
- Do not silently drop content unique to the current repo without listing it as either "graft" or "diff-before-delete."
- Do not import mechanisms wholesale without checking whether they apply to this repo's setup (marketplace update-checks, org-specific CLIs, private MCP servers).
- Do not execute the plan (copy/delete/rename files) as part of this skill — only produce the plan.
- Do not skip the user-review checkpoint (Step 5) even when the rubric scores look clear-cut — a lopsided total can still hide a base-direction call the user wants to make differently.

## Workflow

### Step 1 — Resolve inputs

Determine (from the user's request or by asking one question if ambiguous):
- `LOCAL_PATH` — the plugin/skills folder to evaluate, e.g. `plugins/powerbi/skills`
- `REFERENCE_PATH` — the external/reference skills folder to compare against, e.g. `C:\Development\skills-for-fabric-1\plugins\powerbi-authoring\skills`

If the user doesn't specify `REFERENCE_PATH`, default to the sibling plugin under `C:\Development\skills-for-fabric-1\plugins\` that matches `LOCAL_PATH`'s domain (e.g. `powerbi` → `powerbi-authoring`, `fabric` → `fabric-authoring`/`fabric-consumption`/`fabric-operations`).

### Step 2 — Enumerate and match skills

List both directories (`list_dir` on each `skills/` folder). Match skills by function/description overlap, not just literal name. Record the name mapping explicitly (e.g. `pbi-report-design ↔ powerbi-report-design`). Flag any skill that exists only on one side — these skip scoring and go straight to disposition classification (Step 6).

### Step 3 — Read and compare each matched pair

For every matched pair:
- Read both `SKILL.md` files in full.
- List both `references/` (and `scripts/`, `assets/`) folder contents.
- Bucket every reference file into one of three groups:
  - **Local-only, cost-effective** — no external equivalent, or materially deeper content → candidate to graft into the merged skill
  - **External-only** — candidate to adopt as-is
  - **Same-named on both sides** — candidate to diff-before-delete/replace; check for repo-specific customizations before discarding the local version

### Step 4 — Score against the quality rubric

Apply [`references/skill-quality-rubric.md`](references/skill-quality-rubric.md) (7 dimensions, 1–5 each, /35 total) to **both** sides of every matched pair. This score — not content depth — determines the recommended "base" direction for that skill.

> Note: no official Anthropic-published numeric framework exists for this. This rubric is a practical operationalization of Anthropic's public Claude Skills authoring guidance (progressive disclosure, degrees-of-freedom matching, conciseness, no duplication). Present totals as directional, not authoritative.

**Step 4a — Objective validation (skill-creator).** Before finalizing scores, run `python plugins/skill-creator/skills/skill-creator/scripts/quick_validate.py <skill-path>` against both sides of every matched pair. It checks things a human eyeballing a rubric can miss or misjudge: valid YAML frontmatter, required `name`/`description` fields, kebab-case naming, description length/angle-bracket rules. Treat any failure as a fact that constrains the score, not just a hint:
- A `quick_validate.py` failure on frontmatter/description caps that side's **Description/trigger quality** dimension at 2.
- A missing or non-semver `metadata.version` (which `quick_validate.py` doesn't check but is easy to eyeball alongside it) caps **Version hygiene** at 2, per the existing rubric definition.

**Step 4b — Optional deep evaluation (skill-creator, high-stakes pairs only).** The rubric and validator both assess *architecture*, not runtime behavior. When a disposition is genuinely contested (scores are close, or the pair includes a skill with bundled scripts/agents where behavior matters more than structure), offer to run skill-creator's full eval loop instead of guessing from the rubric alone: draft 2-3 realistic test prompts, run them through both candidate skills via subagents (skill-creator's "Running and evaluating test cases" workflow), grade with `agents/grader.md`, and show the user the benchmark viewer. This is optional and materially more expensive (spawns subagents) — use it only when the user wants that level of rigor or the static signals disagree with each other.

### Step 5 — User review checkpoint (before drafting the plan)

Do not proceed to disposition classification or plan generation on an unreviewed score. For every matched pair, show the user:
- The rubric totals per side (Step 4) and which dimensions drove the gap
- Any `quick_validate.py` failures and which dimensions they capped (Step 4a)
- Deep-eval results if Step 4b was run
- The **recommended** base direction implied by the above

Ask the user to confirm or override the recommended direction per skill before continuing. Record any override verbatim in the final plan's Decisions section (Step 7) with the user's stated reason — this is what distinguishes a reviewed plan from an auto-generated one. Skills with an obvious, uncontested disposition (e.g. reference-only skills with no local equivalent) can be batched into a single confirmation rather than reviewed one-by-one, but every disposition must still be shown before the plan is written.

### Step 6 — Classify disposition per skill

Assign exactly one disposition to every skill found in Step 2, using the direction confirmed (or overridden) in Step 5:

| Disposition | When |
|---|---|
| **Already aligned** | Architecture already matches reference; verify no drift |
| **Merge, reference as base** | Reference scores higher on the rubric; graft local's unique/deeper content on top |
| **Merge, local as base** | Local scores higher, or reference lacks needed content; graft reference's unique content instead |
| **Import wholesale** | Reference-only skill fills a genuine capability gap in the local repo |
| **Keep as-is** | Local-only skill, no reference counterpart |
| **Exclude** | Reference-only skill/mechanism that doesn't apply here (e.g. a marketplace update-check tied to a release channel this repo doesn't use) — state the reason explicitly |

### Step 7 — Generate the plan document

Produce a Markdown plan following [`references/merge-plan-template.md`](references/merge-plan-template.md):

1. Title + one-line strategy statement
2. TL;DR
3. Skill-by-Skill Inventory & Disposition table
4. Detailed Merge Plans — one subsection per skill needing a merge or import, each with a "cost-effective additions" table and a "do NOT bring over" list
5. Steps — phased implementation order; call out which steps are parallel-safe
6. Verification — grep-able / file-existence checks per phase
7. Decisions — choice + rationale + alternative considered, one per non-obvious call
8. Further Considerations — open risks, environment-specific adaptations to preserve
9. Skill Quality Rating table (from Step 4, including any Step 4a validation caps applied), with the "not an official framework" caveat repeated

### Step 8 — Save the plan

Write the plan to `plans/<slug>.plan.md` (kebab-case slug describing the migration). Do not leave the final plan only in chat or session memory — plans are durable repo artifacts, matching the existing precedent in `plans/skill-merge.plan.md`.

## Reference Files

| File | When to read |
|---|---|
| [`references/skill-quality-rubric.md`](references/skill-quality-rubric.md) | Before scoring any skill pair (Step 4) |
| [`references/merge-plan-template.md`](references/merge-plan-template.md) | Before writing the final plan document (Step 7) |

## Relationship to Other Skills

- Produces input for a subsequent execution pass — once the plan is approved, actual file copies/merges/renames are carried out using standard file tools, phase by phase, not by this skill.
- Complements `powerbi-report-authoring` and `powerbi-semantic-model-authoring` (or their successors): this skill decides *what should change about the skills themselves*; those skills are the subject of the comparison, not the tool doing it.
- Depends on `skill-creator` (`plugins/skill-creator/skills/skill-creator`) for two things this skill doesn't implement itself: objective frontmatter/structure validation (`scripts/quick_validate.py`, Step 4a) and, optionally, full behavioral evals for contested pairs (`agents/grader.md` + eval loop, Step 4b). This skill still owns the architecture rubric, disposition logic, and plan document — skill-creator is a scoring input, not a replacement for the merge-planning workflow.
