---
name: dax-data-quality
description: |
  Build a metadata-driven Power BI Data Quality (DQ) framework using Power Query for per-row checks and DAX measures for rules registry and aggregation.
  Use when the user asks to validate data quality, identify bad datapoints, detect duplicates/blanks, enforce expected types/domains/ranges, or build an exceptions view in a semantic model. Favors Power Query for row-level flag computation + DAX for aggregation + governance.
metadata:
  version: 0.2.0
---

# Data Quality Framework — Power Query–First Approach

This skill creates a **repeatable Data Quality (DQ) framework** with **separation of concerns**:

- **Power Query** — Per-row DQ flags (blanks, duplicates, type validation, FK missing, domain checks)
  - Single evaluation per refresh; no re-calculation per filter context
  - All transformations visible in Applied Steps; easier to test + audit
  - M language familiar to BI teams; fewer TMDL syntax errors
  
- **DAX Rules Registry** — `DQ_Rules` table with manual model metadata
  - Declares key fields, expected types, domains, ranges, RI rules
  - DQ_Rules joined to manual model inventory for coverage reporting
  
- **DAX Measures + Report Pages** — Aggregation, KPIs, drill-through exceptions
  - Reference pre-computed PQ flags, no row-level recalculation
  - Show exceptions (drill-through on `RowHasIssues = 1`) with individual flag columns

> **Benefit:** ~10–20% memory reduction for large fact tables; simpler maintenance; better LLM + user experience.

---

## Prerequisites

This skill generates **Power Query (M) transformations** to add per-row DQ flags, plus **TMDL files** for DAX aggregation logic in PBIP projects. Before implementing output:

1. **Read the [PBIP skill](../pbip/SKILL.md)** — Covers Power BI Project structure, `.pbip` filesystem layout, and cascading renames.
2. **Read the [TMDL skill](../tmdl/SKILL.md)** — For DAX measures and `DQ_Rules` table structure (indentation rules, name quoting, property depth, `///` descriptions).
3. **Ensure `pbip-validator` agent is available** — You will run it in Step 5 to validate generated TMDL before opening in Power BI Desktop.

---

## ⚠️ Power Query Output Rules (M Transformations)

When this skill generates **PQ transformations** for per-row flags:

1. **Use `Table.AddColumn()`** to append each flag column to the source table.
2. **Chain transformations** in the Applied Steps UI — each flag is one step, making it auditable.
3. **Use `try...otherwise` for type validation** — e.g. `try Value.From([Col]) otherwise null`
4. **Use `Table.Group()` for duplicate detection** — Single-pass grouping by key columns.
5. **Use `List.Contains()` or similar for domain checks** — e.g. `if [Col] in {"A","B","C"} then 1 else 0`
6. **For foreign key checks:** Use `Table.NestedJoin()` or `Table.Join()` with left-outer merge; mark missing as `[DimKey] = null`.

### Example: Adding a Blank Check to FactLoan
```m
let
  Source = FactLoan_RawData,  // Reference an existing query; never use Csv.Document() with a file path
  DQFlags_IsBlank = Table.AddColumn(
    Source,
    "LoanID_IsBlank",
    each if Text.Trim([LoanID]) = "" or [LoanID] = null then 1 else 0,
    type number
  )
in
  DQFlags_IsBlank
```

---

## ⚠️ TMDL Output Rules (DAX Measures & Rules Table Only — PBIP Projects)

When this skill is used in a **PBIP project**, **per-row DQ flags are added via Power Query** — NOT TMDL. 

TMDL is used **only** for:
- `DQ_Rules` table (rules registry: what to validate)
- `DQ_Rules_WithModelType` calculated table (join rules to model inventory)
- Measures: `DQ - Invalid Rows`, `DQ - Invalid Rows %`, etc. (reference pre-computed PQ flags, no row-level recalculation)

> For complete TMDL syntax reference including indentation, quoting, and property ordering, see [TMDL skill § Syntax Rules](../tmdl/SKILL.md#syntax-rules).

### Correct TMDL measure syntax
```tmdl
	measure 'DQ - Invalid Rows' = 
		CALCULATE(COUNTROWS(FactLoan), FactLoan[RowHasIssues] = 1)
```

### Rules — NEVER break these
1. Use **tabs** for indentation (never spaces). One tab = one depth level.
2. For measures, use `measure` keyword with quoted table names if they have spaces
3. The DAX expression goes after `=` on the same or next line.
4. For calculated tables: Use a **new `.tmdl` file** in `definition/tables/` plus a `ref table` entry in `model.tmdl`.


---

## When to Use This Skill
Activate when the user asks to:
- "create a data quality framework" / "DQ framework" / "data validation" in Power BI
- "move DQ checks to Power Query" / "compute flags in PQ"
- "detect blanks / duplicates / invalid values" in Power Query
- "validate data types" (numeric/date/text validation before loading to semantic model)
- "show bad datapoints" / "exceptions" / "invalid records" pages in report

- "rule registry" / "validation rules table"

**Prefer this approach when:**
- You have Power BI PBIP projects (allows M and DAX separation)
- Data volumes are large; pre-computed flags are more efficient than DAX recalculation per filter
- You want audit trails (M transformations visible in Applied Steps)
- Your BI team is comfortable editing M code

**Alternative: Use upstream validation** (dataflows / Azure Data Factory / SQL) when:
- Transformations are very complex (regex, ML scoring, external APIs)
- DQ is shared across multiple BI tools
- You want PQ for ETL staging only, not semantic model flags

---

## Required Inputs (Ask Once)
If the user hasn't provided these, ask **once up front**:
1) **Target tables** (list of table names). Ask if they are Fact vs Dim if known.
2) **Key columns** per table (single or composite). If unknown, propose candidates.
3) **Foreign keys** and expected dimension tables (for RI checks).
4) **Critical fields** (optional): only validate keys + critical fields, or all columns?
5) **Custom rules** the user wants to add (plain English or CSV rows).

---

## Output Contract (Always Produce)
Produce artifacts in this order:

### A) Model Inventory (Manual — For Rules Coverage)
- `Model_Columns` table (Power Query or manual CSV) — used to cross-reference rules to actual model columns
- Optional: Create a simple mapping of table names and column names via Power Query

### B) Rules Registry
- Generate populated rows for `documents/dq_rules.generated.csv` using the schema in `references/dq-rules-schema.md`
- **YOU (LLM) output:** CSV rows for each rule. Do NOT attempt to run the PowerShell conversion script — that is a user action.
- **USER action:** Run `scripts/Convert-DQRulesToPQ.ps1` to convert the CSV to an inline M query, then paste into the `DQ_Rules` blank query in Power Query Advanced Editor.
- **`DQ_Rules` must include an `ExpectedType` column** (used by `DQ - Rules Coverage %` measure)
- Rule-to-column mapping is done via TMDL joins or measures, not a pre-computed calculated table

### C) Per-table DQ Checks (Power Query — M Code Snippets)
For each target table, generate **M code templates** for:
- `<Key>_IsBlank` — `Text.Trim([KeyCol]) = "" or [KeyCol] = null`
- `<Key>_IsDuplicate` — Use `Table.Group()` to mark duplicates (batch operation)
- `<Col>_IsValidNumber` — `try Value.From([Col]) otherwise null` → check for error
- `<Col>_IsValidDate` — `try Date.From([Col]) otherwise null` with Culture parameter for regional formats
- `<Col>_IsAllowed` — `if [Col] in {"A","B","C"} then 1 else 0`
- `<FK>_IsMissingInDim` — Left merge to dimension table, mark missing as `[DimKey] = null`
- `RowHasIssues` — Combine flags: `[IsBlank]=1 or [IsDuplicate]=1 or ...`

### D) Background Color Measures (DAX — Phase 4 Visual Conditional Formatting)
**NEW** — Generate one color measure per validated business field for severity-coded PBIR highlighting:
- Pattern: `DQ_{FieldName}_BackgroundColor` = `IF({FieldName_ValidationFlag}, "{SeverityHexColor}", "#FFFFFF")`
- Severity map: High=#D13438 (Red), Medium=#F7630C (Orange), Low=#FFB900 (Yellow), None=#FFFFFF (White)
- Display folder: `DQ\Background Colors`
- Used in PBIR `dataPoint` conditional formatting (bind each business field to its color measure)
- **Benefit:** Users instantly see which fields have issues; no custom formatting required in Power BI Desktop

### E) Aggregation Measures + Report Pages (DAX — Phase 4.5 & 5 Governance)
- Measures: `DQ - Invalid Rows`, `DQ - Invalid Rows %`, `DQ - Invalid by RuleType`, `DQ - Rules Coverage %`
- **Phase 4.5 detail measures** (optional): `DQ - Invalid Rules Count`, `DQ - Issues by Severity`, `DQ - {Table} Coverage %`
- **Phase 5 exception pages**: 
  - **dq-exceptions table**: All business fields (not just identifiers) with `dataPoint` formatting bound to color measures
  - **dq-coverage page**: Rule breakdown by severity/type; coverage % per table

### F) Custom Rule Incorporation
After generating the proposed rules pack, ask:
> "Paste the custom rules you want to add (blanks, ranges, domains, RI, conditional rules)."

Then incorporate them into:
- `documents/dq_rules.generated.csv`
- M code snippets (optional: generate new PQ queries for custom rules)

---

## Workflow

> **Model routing — two specialist subagents handle different phases:**
>
> | Phase | Subagent | Model | Handles |
> |-------|----------|-------|---------|
> | Analysis | `dq-analyst` | GPT-5 mini | Requirements, rule design, CSV rows, coverage review |
> | Code gen | `dq-coder` | GPT-4.1 | M transformations, DAX measures, TMDL output |
>
> **As the orchestrating agent**, load this skill and invoke subagents using the `agent` tool (VS Code alias) or `runSubagent` (if available in session). Pass the user's inputs to the analyst first; pass the analyst's output (the rules table) to the coder.

> **Quick Reference — responsibility map:**
>
> | # | Who | What | User does |
> |---|-----|------|-----------|
> | 1 | `dq-analyst` | Gather requirements; propose `Model_Columns` DAX | Paste into semantic model |
> | 2 | `dq-analyst` | Generate CSV rows for `dq_rules.generated.csv` | Run `Convert-DQRulesToPQ.ps1`; paste output as `DQ_Rules` query |
> | 3 | `dq-coder` | Generate M steps for all flag columns | Apply in PQ Advanced Editor |
> | 4 | `dq-coder` | Generate DAX aggregation measures + TMDL | Add to `_Measures.tmdl` |
> | 4.5 | `dq-coder` | Generate color measures for each business field | Add to `_Measures.tmdl`; displayFolder: `DQ\Background Colors` |
> | 5 | `dq-coder` | Generate PBIR JSON patch with conditional formatting | Apply to dq-exceptions table visual |
> | 6 | You (orchestrator) | Review color rendering in Power BI Desktop | Validate user experience; adjust colors if needed

---

### Step 1 — Gather Requirements & Inventory

**→ Invoke `dq-analyst` subagent:**

```
Prompt: "Analyse the following tables and propose a model inventory DAX query plus an initial
list of DQ rules in CSV format. Tables: [paste table list + column names here]"
```

The analyst will return:
- A `Model_Columns` DAX calculated table definition
- An initial set of CSV rows (one per rule) ready for `dq_rules.generated.csv`

If the analyst asks clarifying questions, relay them to the user before continuing.

### Step 2 — Rules Registry (CSV → Inline PQ JSON)

**→ After the analyst delivers CSV rows**, save them to `documents/dq_rules.generated.csv`.

**User runs the conversion script:**

```powershell
# All tables → console
powershell -ExecutionPolicy Bypass -File plugins/powerbi/skills/dax-data-quality/scripts/Convert-DQRulesToPQ.ps1

# Single table → save to file
powershell -ExecutionPolicy Bypass -File plugins/powerbi/skills/dax-data-quality/scripts/Convert-DQRulesToPQ.ps1 -TableFilter "FactLoan" -OutFile "dq_rules_query.pq"
```

Paste the script output into a new blank query named `DQ_Rules` in Power Query Advanced Editor. Works in Desktop and Power BI Service — no file dependencies.

Build coverage table (from analyst output or generate yourself):

```DAX
DQ_Rules_WithModelType =
NATURALLEFTOUTERJOIN(
    DQ_Rules,
    Model_Columns
)
```

### Step 3 — Generate Per-table DQ Checks (Power Query — M Code)

**→ Invoke `dq-coder` subagent**, passing the finalised rules table:

```
Prompt: "Generate Power Query M steps for all rules in this table. Source query variable
is [SourceQueryName]. Apply patterns from references/pq-check-patterns.md.
Rules:
[paste CSV rows or markdown table from Step 2]"
```

The coder will produce complete, chained `Table.AddColumn` steps plus a `RowHasIssues` combiner. Paste each block into the relevant Power Query query's Advanced Editor.

### Step 4 — Build DAX Aggregation Measures

**→ Invoke `dq-coder` subagent** for DAX:

```
Prompt: "Generate DAX aggregation measures and TMDL syntax for these flag columns in FactLoan:
[list flag column names from Step 3]. Table name is [TableName]."
```

The coder outputs TMDL-ready measure blocks. Add them to `_Measures.tmdl`.

### Step 4.5 — Generate Background Color Measures (Phase 4 Visual Highlighting)

**NEW** — For user-facing exceptions reporting:

**→ Invoke `dq-coder` subagent** for color measures:

```
Prompt: "Generate background color measures for conditional PBIR formatting.
For each validated business field, create:
DQ_{FieldName}_BackgroundColor = IF({ValidationFlag}, \"{SeverityHexColor}\", \"#FFFFFF\")

Severity map:
  - High (#D13438 Red): AscentDealId, CommitmentBalance
  - Medium (#F7630C Orange): InitialFunding, GLDate, Probability, TargetFund  
  - Low (#FFB900 Yellow): ClosedDate, Stage, Spread, PropType
  
Display folder: DQ\Background Colors"
```

The coder outputs TMDL color measure blocks. Add them to `_Measures.tmdl`.

### Step 5 — Build Report Pages with Conditional Formatting (Phase 5)

**Three-page design:**

#### 5a) Overview Page
- KPI cards: `Invalid Rows`, `Invalid Rows %`, `Rules Coverage %`
- Charts: Invalid row count by table; severity distribution

#### 5b) Exceptions Page — Business Fields with Color Highlighting
**→ Invoke `dq-coder` subagent** to generate PBIR JSON patch:

```
Prompt: "Generate PBIR JSON patch for dq-exceptions table. Include 13 business fields:
- Identifiers: AscentDealId, Loan Name, Originator
- Financial: Commitment Balance ($), Initial Funding ($)
- Dates: GL Date, Closed Date
- Categorical: Stage, Probability of Closing, Spread, Target Fund, Prop Type
- Summary: IssueList

Apply dataPoint conditional formatting:
- AscentDealId → DQ_AscentDealId_BackgroundColor
- Commitment Balance ($) → DQ_CommitmentBalance_BackgroundColor
- Initial Funding ($) → DQ_InitialFunding_BackgroundColor
- GL Date → DQ_GLDate_BackgroundColor
- Closed Date → DQ_ClosedDate_BackgroundColor
- Stage → DQ_Stage_BackgroundColor
- Probability of Closing → DQ_ProbabilityOfClosing_BackgroundColor
- Spread → DQ_Spread_BackgroundColor
- Target Fund → DQ_TargetFund_BackgroundColor
- Prop Type → DQ_PropType_BackgroundColor"
```

**Key design:** Show business fields (not validation flags) with severity-coded backgrounds:
- 🔴 **Red** = High severity issues → users fix immediately
- 🟠 **Orange** = Medium severity → monitor closely
- 🟡 **Yellow** = Low severity informational → review in bulk
- ⚪ **White** = Data passes all validations

#### 5c) Coverage Page
- DQ_Rules table visual (all rules by type/severity)
- Coverage % per table

### Step 6 — Apply PBIR JSON Patch (PBIP Only)

After `dq-coder` generates the JSON:

1. Back up current dq-exceptions visual.json
2. Replace with generated patch
3. Open `.pbip` in Power BI Desktop and refresh
4. Verify: colors render correctly, all 13 fields load, drill-through works

### Step 7 — Validate PBIP & DAX (PBIP Only)

Run the **`pbip-validator`** agent:
```
Request: "Validate PBIP project. Check:
- TMDL color measure syntax (tabs, property depth, hex colors)
- PBIR visual.json well-formedness (valid JSON, selector paths)
- Column reference correctness (FactLoan[DQ_*BackgroundColor])
- Color format validation (#RRGGBB)
"
```
Fix errors before publishing to Power BI Service.

---

## PBIR Conditional Formatting Patterns (Phase 4–5)

When generating color measures for visual highlighting, use this PBIR JSON structure in the `dataPoint` objects array:

```json
{
  "objects": {
    "dataPoint": [
      {
        "properties": {
          "fill": {
            "solid": {
              "color": {
                "expr": {
                  "Measure": {
                    "Expression": {"SourceRef": {"Entity": "FactLoan"}},
                    "Property": "DQ_{FieldName}_BackgroundColor"
                  }
                }
              }
            }
          }
        },
        "selector": {"metadata": "FactLoan.{FieldName}"}
      }
    ]
  }
}
```

**Pattern rules:**
1. One `dataPoint` object per validated business field (not per flag column)
2. The `Property` references the color measure name (e.g., `DQ_CommitmentBalance_BackgroundColor`)
3. The `selector.metadata` matches the **business field**, not the flag (e.g., `FactLoan.Commitment Balance ($)`, not `FactLoan.CommitmentBalance_IsInRange`)
4. Color measures return hex strings: `#RRGGBB` format (e.g., `#D13438`, `#F7630C`, `#FFB900`, `#FFFFFF`)

**Result:** Each row's business fields display with color backgrounds derived from their corresponding validation flags, creating an intuitive visual hierarchy by severity.

---

## Guardrails (Performance + Correctness)

**Power Query flags:**
- Single evaluation per refresh; no re-calculation per filter context
- Flags are compressed at load time (boolean columns use ~1 byte per row)
- Avoid computed columns for FK checks if dimension is very large; use left-outer merge instead

**DAX aggregation:**
- Always filter visual by pre-computed flags, not DAX FILTER() expressions
- Reference flags with fully qualified names: `FactLoan[RowHasIssues]`
- Measures are fast because they reference already-computed columns, not row-level DAX

**Color measures** (Phase 4–5):
- Color measures use simple IF logic: `IF(Flag, HexColor, DefaultColor)` — evaluated per row at render time, negligible cost
- PBIR conditional formatting (dataPoint objects) references color measures without materializing new columns
- Benefit: Severity-coded visual highlighting without model bloat; users see issue severity at a glance
- Store color measures in display folder `DQ\Background Colors` for user organization

**Audit trail:**
- M transformations visible in Applied Steps; easy to trace where flags come from
- `DQ_Rules` table is the single source of truth; version control it in PBIP `/definition/tables/`
- Document assumptions in rule names (e.g., `DQ_AssetID_IsDuplicate - Composite Key: AssetID, Year`)

---

## Common Pitfalls (Lessons from Production)

These errors have occurred when applying this skill in Power Query contexts. Avoid them.

### P1 — Duplicate detection: iterative check vs. single-pass grouping
**Wrong** (slow; iterates each row against all others):
```m
[IsDuplicate] = List.Count(List.Select(Source[KeyCol], each _ = [KeyCol])) > 1
```
**Correct** (fast; single `Table.Group()` pass):
```m
let
  Grouped = Table.Group(Source, {"KeyCol"}, {{"Count", Table.RowCount}}),
  Marked = Table.Join(Source, {"KeyCol"}, Grouped, {"KeyCol"}, JoinKind.LeftOuter),
  HasDuplicates = Table.AddColumn(Marked, "IsDuplicate", each [Count] > 1)
in
  HasDuplicates
```

### P2 — Date parsing: regional format assumptions
**Wrong** (assumes US format MM/DD/YYYY; fails in EU):
```m
[IsValidDate] = try Date.FromText([DateCol]) otherwise null
```
**Correct** (explicit culture parameter):
```m
[IsValidDate] = try Date.FromText([DateCol], "en-US") otherwise null
// OR use culture from query parameter if data comes from multiple regions
```

### P3 — Foreign key checks: merge order and null handling
**Wrong** (marks all missing as duplicates):
```m
let
  Joined = Table.Join(Source, {"FK"}, Dimension, {"DimKey"}, JoinKind.RightOuter)
in
  Joined
```
**Correct** (left-outer; null on dimension side indicates missing FK):
```m
let
  Joined = Table.NestedJoin(Source, {"FK"}, Dimension, {"DimKey"}, "Dim", JoinKind.LeftOuter),
  Expanded = Table.ExpandTableColumn(Joined, "Dim", {"DimKey"}, {"DimKey"}),
  IsMissing = Table.AddColumn(Expanded, "FK_IsMissing", each [DimKey] = null)
in
  IsMissing
```

### P4 — Type validation: `try...otherwise` vs. format-specific checks
**Wrong** (catches all errors, including column-not-found):
```m
[IsValidNumber] = try [Amount] otherwise null
```
**Correct** (specific type conversion with null indicator):
```m
[IsValidNumber] = try (if Value.Is(Value.FromText([Amount]), type number) then 1 else 0) otherwise null
```

### P5 — Case sensitivity in domain checks
**Wrong** (fails if data has "Apple", "APPLE", "apple"):
```m
[IsAllowed] = if [Fruit] in {"apple", "banana"} then 1 else 0
```
**Correct** (normalize case):
```m
[IsAllowed] = if Text.Lower([Fruit]) in {"apple", "banana"} then 1 else 0
```

### P6 — Combining flags: use simple boolean logic
**Wrong** (complex nested IF with no column reference):
```m
[RowHasIssues] = if [IsBlank] = 1 then 1 else if [IsDuplicate] = 1 then 1 else if [IsValidNumber] = 1 then 0 else 1
```
**Correct** (clear OR logic visible in Applied Steps):
```m
[RowHasIssues] = [IsBlank] = 1 or [IsDuplicate] = 1 or [IsValidNumber] <> 1
```

### P7 — Missing ExpectedType column in DQ_Rules
The standard `DQ - Rules Coverage %` measure references `DQ_Rules[ExpectedType]`. If you load `DQ_Rules` without this column, the measure will fail. Always include `ExpectedType` in the rules registry (can be null if rule is not a type check).

### P8 — Conditional formatting: Selector metadata must match business field, not flag
**Wrong** (references flag column; no formatting appears):
```json
"selector": {"metadata": "FactLoan.CommitmentBalance_IsInRange"}
```
**Correct** (references business field; formatting appears on correct column):
```json
"selector": {"metadata": "FactLoan.Commitment Balance ($)"}
```

### P9 — Color measure hex strings must include # and be 7 characters
**Wrong** (invalid hex; Power BI ignores):
```dax
IF([Flag], "D13438", "#FFFFFF")  // Missing # on first color
```
**Correct** (valid hex):
```dax
IF([Flag], "#D13438", "#FFFFFF")  // Both colors have #RRGGBB format
```

### P10 — PBIR dataPoint formatting only works on visual fields, not measures directly
**Wrong** (trying to format a measure; won't work):
```json
"selector": {"metadata": "FactLoan.DQ_CommitmentBalance_BackgroundColor"}
```
**Correct** (format the business field; bind to color measure):
```json
{
  "selector": {"metadata": "FactLoan.Commitment Balance ($)"},
  "properties": {
    "fill": {
      "solid": {
        "color": {"expr": {"Measure": {"Property": "DQ_CommitmentBalance_BackgroundColor"}}}
      }
    }
  }
}
```

---

## Files in This Skill
- `SKILL.md` (this file — orchestrator instructions)
- **Agents** (model-routed subagents):
  - `.github/agents/dq-analyst.agent.md` — GPT-5 mini; rules design, requirements analysis, CSV generation
  - `.github/agents/dq-coder.agent.md` — GPT-4.1; M code, DAX measures, TMDL output
- **Scripts:**
  - `scripts/Convert-DQRulesToPQ.ps1` — Converts `dq_rules.csv` → inline M JSON for the `DQ_Rules` Power Query table
- **References:**
  - `references/dq-rules-schema.md` — Rules registry schema & CSV column definitions
  - `references/pq-check-patterns.md` — M code snippets for each flag type
  - `references/report-layout.md` — Suggested report pages & measures
- **Examples:**
  - `examples/example-pq-fact-loans.md` — Full walkthrough: PQ flags + DAX aggregation
