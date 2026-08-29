# Merge Plan Template

Structure to follow when generating a merge/migration plan (Step 7 of the main workflow, after the Step 5 user review checkpoint). This is the same shape as `plans/skill-merge.plan.md` and the powerbi-authoring migration plan produced in-session — copy this skeleton, fill every placeholder, and delete this comment block.

```markdown
# Migration Plan: <one-line strategy statement, e.g. "Adopt <reference> as Primary Base">

> **Strategy:** <One sentence: which side becomes base, which side is donor, and why in one clause.>

---

## TL;DR

<3-5 sentences: what the reference collection has that's more mature, what precedent this extends (if any), and the net outcome — X skills merged with reference as base, Y skills imported wholesale, Z skills kept untouched.>

---

## Skill-by-Skill Inventory & Disposition

| Reference | Local | Disposition |
|---|---|---|
| `<reference-skill>` | `<local-skill-or-none>` | **<Already aligned / Merge, reference as base / Merge, local as base / Import wholesale / Keep as-is / Exclude>** |
| ... | ... | ... |

**Confirmed infrastructure compatibility:** <note any shared dependency, e.g. common/*.md reference folders, CLI tools, MCP servers, that make cross-repo skill adoption safe without modification.>

---

## Detailed Merge Plans

### N. `<merged-skill-name>` ← `<local-skill-name>` (<reference|local> is base)

**<Reference|Local> architecture to adopt as base:**
- <bullet list of structural features: workflow steps, routing tables, governance blocks, reference file list>

**Cost-effective additions to graft from <the donor side>:**

| File | Why keep it | Action |
|---|---|---|
| `<file>.md` | <why it's deeper/unique/not covered by the base side> | <Add as new reference file / merge into existing file / etc.> |

**Do NOT bring over:** <files superseded by an equivalent on the base side — name the superseding file and note "diff first for unique content before discarding" for any same-named pairs.>

**Structural fixes required regardless of source:**
- <phantom references to remove, version fixes, governance blocks to adopt, etc.>

### N+1. Import Wholesale: `<reference-only-skill>`

Copy `<full path>` verbatim. Fills a real gap: <what capability is missing locally and why it matters>.

**Follow-up:** <any adjustments needed post-import, e.g. repointing identity strings, updating companion agent files.>

### N+2. Exclude: `<reference-only-mechanism>`

<Name the skill/mechanism.> Not imported because <reason — e.g. it depends on a marketplace/release channel this repo doesn't use>. If any reference skill or file ships an invocation block pointing at the excluded mechanism, strip that block during the corresponding merge/import step rather than leaving a phantom reference.

---

## Steps (Implementation Order)

### Phase 1 — Wholesale Imports (parallel, no dependencies)
1.1 ...
1.2 ...

### Phase 2 — Verify Already-Aligned Skills (independent)
2.1 Diff against the reference's latest version to confirm no drift since any prior merge.

### Phase 3 — Merge <skill-name> (depends on: <note anything it should follow, e.g. Phase 1 for a shared dependency>)
3.1 Copy reference skill wholesale into the new/target folder
3.2 Graft cost-effective reference files identified above
3.3 Add routing-table rows for each grafted reference
3.4 Diff same-named overlapping files; port unique content, then delete the superseded version
3.5 Delete the old local skill folder once verified
3.6 Update all cross-references elsewhere in the repo (README, AGENTS.md, agent files) to the new skill name

### Phase N — Repo-Level Wiring (depends on prior phases)
N.1 Update plugin README skill list and descriptions
N.2 Update AGENTS.md / CLAUDE.md skill references
N.3 Update agent files to reference new skill names and route through any newly-imported skills

### Phase N+1 — Cleanup & Version Hygiene
- Ensure every skill has semver `metadata.version`
- Remove any remaining phantom references repo-wide
- Re-run any existing verification scripts (BPA, template checks, etc.) to confirm no regression from renames

---

## Verification

1. `<target skills folder>` contains exactly: <final expected list> — no stale folders remain
2. `grep -r "<phantom reference string>"` across `<scope>` → 0 matches
3. `grep -r "<old-skill-name>"` across the repo → 0 matches (all renamed)
4. Every grafted reference file is cross-linked from its new parent SKILL.md routing table
5. All SKILL.md files have `metadata.version` in semver format
6. <any skill-specific regression check, e.g. BPA script / template report still function>

---

## Decisions

### Decision N: <short title>
**Choice:** <what was decided>
**Rationale:** <why>
**Alternative considered:** <what else was possible, and why it was rejected>

---

## Further Considerations

1. **Environment-specific adaptations** — if the user has customized any local file that's superseded by a reference equivalent, diff line-by-line for environment-specific values before deleting.
2. **Agent file updates are non-trivial** — renames require careful find-and-replace plus a re-read of workflow logic, not a blind text substitution.
3. <any other open risk or follow-up>

---

## Skill Quality Rating — <Rubric name/version> (1–5 scale, /35 total)

> Not an official Anthropic-published framework — see `references/skill-quality-rubric.md` for the caveat and dimension definitions.

| Dimension | `<local-skill>` (local) | `<reference-skill>` (reference) |
|---|---|---|
| Conciseness / context cost | | |
| Progressive disclosure | | |
| No duplication | | |
| Degrees-of-freedom matching | | |
| Description/trigger quality | | |
| No extraneous files | | |
| Version hygiene (semver) | | |
| **Total (/35)** | | |

**Reading the scores:** <1-2 sentences per skill pair on what the score gap implies for the recommended base direction, and what it does NOT capture (content depth — covered separately above).>
```
