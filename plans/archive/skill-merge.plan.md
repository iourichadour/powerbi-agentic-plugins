# Skill Merge Plan: `powerbi-report-authoring`

> **Goal:** Produce a single, production-grade `powerbi-report-authoring` skill by merging the best of both versions.
>
> - **New (base):** `C:\Development\skills-for-fabric-1\plugins\powerbi-authoring\skills\powerbi-report-authoring`
> - **Old (donor):** `C:\Development\powerbi-agentic-plugins\plugins\powerbi\skills\powerbi-report-authoring`
> - **Target:** `C:\Development\powerbi-agentic-plugins\plugins\powerbi\skills\powerbi-report-authoring` (replace Old with merged result)

---

## 1. Analysis Summary

### Scores Before Merge

| Dimension | Old | New |
|-----------|-----|-----|
| Coverage & Completeness | 6 | 9 |
| Actionability (step-by-step) | 7 | 9 |
| CLI / Tooling Integration | 2 | 10 |
| Anti-Patterns / Guard Rails | 3 | 10 |
| Schema & JSON Accuracy | 5 | 9 |
| Skill Routing / Composition | 4 | 8 |
| Must/Prefer/Avoid Governance | 0 | 8 |
| Reference Routing Table | 4 | 9 |
| Rendering Verification Loop | 0 | 9 |
| **BPA Script (executable)** | **9** | **0** |
| **Report Template Starter Kit** | **8** | **0** |
| **Token Cost Efficiency** | **8** | **4** |
| Update / Versioning Hygiene | 0 | 6 |
| **Total (130 pt)** | **56 (43%)** | **91 (70%)** |

### What the Old Skill Has That the New Skill Lacks

| Asset | Path in Old Skill | Value |
|-------|-------------------|-------|
| BPA script | `scripts/bpa.ps1` | Downloads PBI Inspector, executes rules against any `.Report` definition folder, outputs GitHub-format violations |
| BPA rules | `scripts/bpa-rules-report.json` | 14 KB of report-specific rules (unused custom visuals, visual count per page, etc.) |
| Template PBIR report | `assets/templateReport/report/` | Full PBIR-format report: `title`, `topCard`, `dateSlicer`, `barChart`, `timeSeries` visuals pre-wired |
| Template KB | `assets/templateReport/template-report-kb.md` | Step-by-step rules for adapting each template visual to any semantic model |
| Dummy semantic model | `assets/templateReport/report.dummyModel/` | Companion model used as the template's local binding; enables Desktop to open without errors |

### What the New Skill Has That the Old Skill Lacks

- `powerbi-report-author` CLI integration (catalog, formatting, validate commands)
- `powerbi-desktop` CLI integration (reload, screenshot loop)
- 30+ documented anti-patterns with consequence + fix
- Must/Prefer/Avoid governance block
- Structured topic routing table (22 reference files with "when to read" guidance)
- Complete Edit→Validate→Reload→Screenshot quality loop
- Explicit skill composition model (design, planning, semantic-model, fabric-cli boundaries)
- `re-theming.md`, `color-strategy.md`, `conditional-formatting.md`, `slicers.md`, and more granular reference files

---

## 2. Merge Strategy

**Base = New skill.** Copy New skill wholesale into the target location, then graft the three Old-skill assets on top. Do **not** revert any New-skill content.

**No content from New shall be removed or weakened.** Every addition from Old is additive.

---

## 3. Work Items

### WI-1 — Copy `scripts/` from Old into New

**Action:** Copy the two files below into the merged skill's `scripts/` folder.

| Source (Old) | Destination (Merged) |
|---|---|
| `scripts/bpa.ps1` | `scripts/bpa.ps1` |
| `scripts/bpa-rules-report.json` | `scripts/bpa-rules-report.json` |

**Required edit to `bpa.ps1`:** The default `$reports` parameter currently hard-codes `C:\temp\202602\PBIP\Sales.Report\definition`. Remove that default; make the parameter mandatory so the agent always supplies an explicit path.

```powershell
# Before
$reports = @("C:\temp\202602\PBIP\Sales.Report\definition")

# After — no default; caller must supply -reports
[Parameter(Mandatory=$true)]
[string[]]$reports
```

**Validation:** Run the script against any sample `.Report/definition` folder to confirm PBI Inspector downloads and executes without errors.

---

### WI-2 — Copy `assets/` from Old into New

**Action:** Copy the entire `assets/templateReport/` tree into the merged skill.

| Source (Old) | Destination (Merged) |
|---|---|
| `assets/templateReport/` (full tree) | `assets/templateReport/` |

This includes:
- `report/` — full PBIR definition (pages, visuals, StaticResources)
- `report.dummyModel/` — companion local semantic model for Desktop binding
- `template-report-kb.md` — visual adaptation rules
- `report-layout.png` — reference layout screenshot
- `templateReport.pbip` — project manifest

**No edits needed** — these files are self-contained.

---

### WI-3 — Add BPA Task Section to `SKILL.md`

**Action:** Add a new `## Task: Analyze report against best practices` section to the merged `SKILL.md`, placed after the `## Task: Rebind Power BI Report to a different semantic model` section and before `## Post-development: Validate Changes`.

**Content to insert:**

````markdown
## Task: Analyze report against best practices

Run the BPA script against the report definition using PBI Inspector. If no specific rules are mentioned, use the default rule set in `scripts/bpa-rules-report.json`.

1. **Run BPA** — Execute the script, passing the path to the report's `definition` folder:

    ```powershell
    scripts/bpa.ps1 -reports "<path-to-.Report/definition>"
    ```

    To use a custom rules file:

    ```powershell
    scripts/bpa.ps1 -reports "<path-to-.Report/definition>" -rulesFilePath "<path-to-rules.json>"
    ```

    > The script auto-downloads **PBI Inspector** (`win-x64-CLI`) on first run into `scripts/_tools/PBIInspector/`. Requires internet access and Windows x64.

2. **Review findings** — PBI Inspector outputs results in GitHub annotation format. Categorize by severity and propose fixes for each violation:

    | Rule ID | Description | Typical Fix |
    |---------|-------------|-------------|
    | `REMOVE_UNUSED_CUSTOM_VISUALS` | Custom visual imported but not used on any page | Remove from `report.json → publicCustomVisuals` |
    | `REDUCE_VISUALS_ON_PAGE` | Page exceeds 20 visible visuals | Split into sub-pages or hide non-essential visuals |

3. **Fix and re-validate** — After fixing BPA violations, run `powerbi-report-author validate <path-to-.Report-dir>` to confirm PBIR schema integrity is intact.
````

---

### WI-4 — Update "Create new report" Task in `SKILL.md`

**Action:** Replace the existing step 3 of the `## Task: Create new report on top of semantic model` section to reference the template assets instead of an abstract instruction.

**Current step 3:**
```
3. **Copy template files** — Copy `assets/templateReport/report/definition` and `assets/templateReport/report/StaticResources` to the `*.Report` folder.
```

This step already references `assets/templateReport/` — it is valid as-is if the `assets/` folder is present. After WI-2 lands, this step becomes functional. **No rewrite needed.**

**However**, add a callout after step 3 pointing to the knowledge base file:

```markdown
    > **Template knowledge base:** After copying the template files, read
    > [`assets/templateReport/template-report-kb.md`](assets/templateReport/template-report-kb.md)
    > for exact instructions on how to adapt each visual (`title`, `topCard`,
    > `dateSlicer`, `barChart`, `timeSeries`) to the target semantic model's
    > tables, columns, and measures.
```

---

### WI-5 — Add Topic Routing Entry for BPA and Template

**Action:** Add two rows to the `## Topic Files and Examples` routing table in `SKILL.md`:

| File | When to read |
|------|-------------|
| [`assets/templateReport/template-report-kb.md`](assets/templateReport/template-report-kb.md) | Starting from the template report — maps each template visual to semantic model fields |
| [`scripts/bpa-rules-report.json`](scripts/bpa-rules-report.json) | Reference for which BPA rules are active; customize by marking rules `disabled: true` |

---

### WI-6 — Add Token-Cost Note to `SKILL.md`

**Action:** Add a callout box at the top of the `## Topic Files and Examples` section (above the routing table) to guide agents on reading only what is needed.

**Content to insert:**

```markdown
> **Context budget:** Load only the reference file(s) relevant to the current
> task. Do not pre-load all reference files. The full reference set is ~342 KB;
> loading it all doubles prompt cost with no benefit for single-task sessions.
```

---

### WI-7 — Update `SKILL.md` `description` Frontmatter

**Action:** Update the `description` field in the New skill's frontmatter to reflect the merged capabilities (BPA + template).

**Current (New skill):**
```yaml
description: >-
  Create and modify Power BI report files in PBIR/PBIP format using the
  `powerbi-report-author` and `powerbi-desktop` CLIs. Use when the user wants
  to: (1) implement an approved report spec or design brief, (2) add or edit
  pages, visuals, filters, slicers, bookmarks, themes, or formatting, (3)
  validate PBIR and verify rendering in Power BI Desktop. ...
```

**Add to the end of the description list:**
```
(4) scaffold a new report from the built-in template, (5) run Best Practice Analysis (BPA) against a report definition.
```

---

### WI-8 — Bump `metadata.version` in `SKILL.md`

**Action:** Increment the version to reflect the merge.

```yaml
# Before
metadata:
  version: 0.1.0

# After
metadata:
  version: 0.2.0
```

---

## 4. File Manifest After Merge

```text
powerbi-report-authoring/
├── SKILL.md                                          ← Updated (WI-3, WI-4, WI-5, WI-6, WI-7, WI-8)
├── assets/
│   └── templateReport/                               ← NEW from Old (WI-2)
│       ├── report/
│       │   ├── definition/
│       │   │   ├── pages/
│       │   │   │   ├── mainPage/
│       │   │   │   │   ├── page.json
│       │   │   │   │   └── visuals/
│       │   │   │   │       ├── barChart/visual.json
│       │   │   │   │       ├── dateSlicer/visual.json
│       │   │   │   │       ├── logo/visual.json
│       │   │   │   │       ├── timeSeries/visual.json
│       │   │   │   │       ├── title/visual.json
│       │   │   │   │       └── topCard/visual.json
│       │   │   │   └── pages.json
│       │   │   ├── report.json
│       │   │   └── version.json
│       │   ├── StaticResources/RegisteredResources/theme.json
│       │   ├── definition.pbir
│       │   └── .platform
│       ├── report.dummyModel/
│       │   ├── definition/
│       │   │   ├── database.tmdl
│       │   │   └── model.tmdl
│       │   ├── definition.pbism
│       │   └── .platform
│       ├── template-report-kb.md
│       ├── report-layout.png
│       └── templateReport.pbip
├── scripts/                                          ← NEW from Old (WI-1)
│   ├── bpa.ps1                                       ← Edited: remove hardcoded default path
│   └── bpa-rules-report.json
└── references/                                       ← Unchanged (all 22 files)
    ├── authoring.md
    ├── card.md
    ├── cartesian.md
    ├── color-strategy.md
    ├── conditional-formatting.md
    ├── expressions.md
    ├── filter-pane.md
    ├── filters.md
    ├── formatting-overview.md
    ├── formatting.md
    ├── image.md
    ├── map.md
    ├── page-formatting.md
    ├── powerbi-desktop.md
    ├── powerbi-report-author-cli.md
    ├── re-theming.md
    ├── screenshot-review.md
    ├── shape.md
    ├── slicers.md
    ├── table.md
    ├── textbox.md
    ├── theming.md
    └── version-control.md
```

---

## 5. Implementation Order & Dependencies

```
WI-2 (copy assets/)
  └─→ WI-4 (SKILL.md create-report callout)  — needs assets to exist first

WI-1 (copy scripts/ + edit bpa.ps1)
  └─→ WI-3 (SKILL.md BPA task section)        — needs scripts to exist first

WI-5 (routing table rows)                     — depends on WI-2 and WI-1 paths being final
WI-6 (token-cost note)                        — independent
WI-7 (description frontmatter)               — independent
WI-8 (version bump)                          — last; do after all other WIs
```

Parallel execution is safe for `WI-2 + WI-1`, then `WI-3 + WI-4 + WI-5 + WI-6 + WI-7`, then `WI-8`.

---

## 6. Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|---------------|
| AC-1 | `scripts/bpa.ps1` runs against a `.Report/definition` folder without error | Execute: `.\scripts\bpa.ps1 -reports "<any .Report/definition path>"` — expect PBI Inspector to download (first run) and produce output |
| AC-2 | `bpa.ps1` has no hardcoded default path | Grep `bpa.ps1` for `C:\temp` — must return nothing |
| AC-3 | Template report opens in Desktop | Open `assets/templateReport/templateReport.pbip` in Power BI Desktop — no errors |
| AC-4 | `SKILL.md` contains BPA task section | Grep `SKILL.md` for `Analyze report against best practices` |
| AC-5 | `SKILL.md` contains template KB callout in create-report task | Grep `SKILL.md` for `template-report-kb.md` |
| AC-6 | `SKILL.md` routing table includes `template-report-kb.md` and `bpa-rules-report.json` rows | Grep routing table section |
| AC-7 | Token-cost note present above routing table | Grep `SKILL.md` for `Context budget` |
| AC-8 | `metadata.version` is `0.2.0` | Check SKILL.md frontmatter |
| AC-9 | `powerbi-report-author validate` passes on template report | Run: `powerbi-report-author validate assets/templateReport/report` |
| AC-10 | All 22 reference files present and unmodified | `Get-ChildItem references/ | Measure-Object` → 22 files |

---

## 7. Out of Scope

- Editing any of the 22 reference files — they are carried forward as-is.
- Migrating the Old skill's `SKILL.md` task wording into the New — the New skill's task coverage is already a superset.
- Updating `plugin.json` / `plugin.yml` descriptor files — version metadata in those files should be updated in a separate PR once the merge is validated.
- Updating the `powerbi-report` skill description in `available_skills` — that is a separate registry update.

---

## 8. Branch Guidance

> ⚠️ Current branch: `feature/pbi-design-skill` — does **not** follow the required `drv/JIRA-XXX` pattern.
>
> Before implementing any work item, create a compliant branch:
>
> ```bash
> git checkout -b drv/BI-XXX-merge-report-authoring-skill
> ```
>
> Replace `BI-XXX` with the actual Jira ticket number for this merge task.

---

*Plan generated: 2026-08-03 | Analyst: GitHub Copilot CLI*
