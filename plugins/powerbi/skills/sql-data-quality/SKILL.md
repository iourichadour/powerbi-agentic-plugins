---
name: sql-data-quality
description: |
  Build a metadata-driven SQL Server Data Quality (DQ) framework using T-SQL audit VIEWs with per-column DQ flags and a mandatory user approval workflow.
  Use when the user asks to validate data quality in SQL Server tables, audit data for blanks/duplicates/invalid types/domain violations/referential integrity, and surface bad datapoints to Power BI over DirectQuery.
  This skill REQUIRES an explicit approval step: schema is inspected, CSV rules are auto-generated, user reviews and approves before VIEW generation.
metadata:
  version: 0.1.0
---

# SQL Server Data Quality Framework — Audit VIEW Pattern

This skill creates a **repeatable Data Quality (DQ) framework** inside SQL Server with **user approval gates**:

- **Schema Inspection** — Auto-discovery via MSSQL MCP or INFORMATION_SCHEMA queries (PKs, FKs, column types, cardinality)
- **Rules CSV Generation** — Auto-populate `dq_rules.generated.csv` with proposed rules + severities (Error/Warn)
- **User Review & Approval** — Mandatory checkpoint: user reviews CSV, edits as needed, explicitly approves before proceeding
- **Audit VIEW Generation** — Per-table T-SQL `CREATE OR ALTER VIEW` with per-column DQ flag columns (`IsBlank`, `IsDuplicate`, `IsInvalidNumber`, etc.)
- **Power BI Integration** — DirectQuery or Import the audit VIEW; filter by `RowHasIssues = 1`; use `MaxSeverity` for color-coded highlighting

> **Key difference from PQ-first skill:** All flag columns use consistent polarity (`1 = problem`). Output is T-SQL VIEW + audit columns, not Power Query M code. All conversions use `TRY_CAST`, not `Value.From`.

---

## Prerequisites

1. **SQL Server 2016+** (for `CREATE OR ALTER VIEW` and `TRY_CAST`)
   - For SQL Server 2012–2014, see fallback patterns in `references/sql-check-patterns.md` (`ISNUMERIC()`, `ISDATE()`)
2. **MSSQL MCP tools available (optional)** — skill will auto-detect and use if present; otherwise prompts user for connection details
3. **Read the [pbip skill](../pbip/SKILL.md)** — if deploying to PBIP projects (Power BI Desktop)
4. **Ensure user understands the approval workflow** — no auto-execution; all VIEW generation requires explicit sign-off

---

## ⚠️ Workflow Rules

### MANDATORY APPROVAL GATE
This skill **REQUIRES** an explicit approval step at Step 4. CSV is auto-generated; user **must** approve before VIEW generation proceeds.

**No hidden auto-execution.** All VIEW DDL generation is conditional on user approval.

---

## When to Use This Skill

Activate when the user asks to:
- "validate data quality" in SQL Server tables
- "audit this table for blanks/duplicates" / "detect bad data"
- "flag invalid types" (numeric/date/text validation in SQL)
- "domain check" or "referential integrity" in SQL
- "build an audit view for Power BI"
- "generate DQ checks" for a table or set of tables

**Prefer this skill when:**
- Tables live in SQL Server (on-premises, Azure SQL)
- Data volumes are large; VIEW-over-source is more efficient than compute in Power BI
- You want audit trail with explicit schema inspection + user approval
- BI team prefers Power BI DirectQuery over pre-computed staging

**Alternative: Use upstream validation** when:
- Transformations are complex (regex, ML scoring, external APIs) — use dataflows/ADF instead
- Data is already in Power BI; use the `dax-data-quality` skill for DAX-based checks
- You need static materialized tables — add a Phase 2 staging table variant (see guardrails)

---

## Single Canonical Workflow (Mandatory Approval Gate)

### Step 1 — Gather Input (User provides tables + connection)
**→ Agent prompts user:**
```
"Provide the following:
1. Table names to validate (comma-separated, e.g., FactLoan, FactPayment)
2. SQL Server connection: ServerInstance, Database, Schema (default: dbo)
3. Connection method: MSSQL MCP (if available) or manual connection string"
```

### Step 2 — Schema Inspection & CSV Generation (User Review Pending)
**→ Script runs: `Generate-DQRulesCSV.ps1`**
- Via MSSQL MCP (if available): Query `INFORMATION_SCHEMA.COLUMNS`, `KEY_COLUMN_USAGE`, `REFERENTIAL_CONSTRAINTS`, sample TOP 50 DISTINCT per low-cardinality varchar column
- Fallback: Ask user for column list (name, type, nullable) manually
- Auto-generate proposed rules:
  - Primary keys → `KeyNotBlank`, `KeyUnique` (Severity: Error)
  - Foreign keys → `RI` (Severity: Error)
  - `*Amount`, `*Balance`, `*Value` → `TypeNumber`, `Range` (Severity: Warn)
  - `*Date`, `*On`, `*At` → `TypeDate` (Severity: Warn)
  - `*Status`, `*Stage`, `*Category` (cardinality ≤ 20) → `Domain` (Severity: Warn, AllowedValues from sample)
  - Non-nullable text → `KeyNotBlank` (Severity: Warn)
- Output: `documents/dq_rules.generated.csv` (all 14 columns pre-filled)

### Step 3 — Present CSV to User (Edit / Customize)
**→ Agent displays CSV:**
```
TableName | ColumnName | RuleType | Severity | AllowedValues | Notes
----------|------------|----------|----------|----------------|-------
FactLoan  | LoanID     | KeyNotBlank | Error | | Primary key field
FactLoan  | LoanID     | KeyUnique | Error | | Detect duplicates
FactLoan  | Amount     | TypeNumber | Warn | | Value must be numeric
FactLoan  | Amount     | Range     | Warn | 100|9999999 | Amount between $100–$9.99M
FactLoan  | GLDate     | TypeDate  | Warn | | GL post date
FactLoan  | Stage      | Domain    | Warn | Prospecting|Approved|Closed Won | Status domain
FactLoan  | OriginatorID | RI      | Error | DimOriginator.OriginatorID | Foreign key
```

**User can:**
- Edit any row (change RuleType, Severity, AllowedValues, MinValue/MaxValue)
- Delete rows to skip rules
- Add custom rules (paste new CSV rows)
- Confirm: "These rules look good. Proceed to VIEW generation."

### Step 4 — APPROVAL GATE (Mandatory Confirmation)
**→ Agent prompts:**
```
✓ Approve these 7 validation rules for FactLoan?

Summary:
  - Error severity (critical): 3 rules (KeyNotBlank, KeyUnique, RI)
  - Warn severity (quality): 5 rules (TypeNumber, Range, TypeDate, Domain, Duplicate)

[Yes / No / Edit]
```

**Only on "Yes"** → proceed to Step 5. If "No" or "Edit" → loop back to Step 3.

### Step 5 — Post-approval: VIEW Generation
**→ Script runs: `Generate-DQAuditView.ps1`**
- Input: approved `dq_rules.generated.csv`
- Output: T-SQL `CREATE OR ALTER VIEW [dbo].[TableName_DQ_Audit] AS ...` with:
  - All flag columns (one per rule: `IsBlank`, `IsDuplicate`, `IsInvalidNumber`, `IsInvalidDate`, `IsOutOfDomain`, `IsOutOfRange`, `IsMissingInDim`)
  - `RowHasIssues` (computed column: `1` if ANY flag = 1)
  - `MaxSeverity` (computed column: worst triggered rule severity — `Error`, `Warn`, or NULL)
  - `IssueList` (semicolon-delimited concatenation of triggered flag names)
- Usage: `powershell -ExecutionPolicy Bypass -File plugins/powerbi/skills/sql-data-quality/scripts/Generate-DQAuditView.ps1 -CsvPath documents/dq_rules.generated.csv -OutFile output/FactLoan_DQ_Audit.sql`
- Optional: add `-Execute -ServerInstance "localhost" -Database "MyDB"` to deploy directly via `Invoke-Sqlcmd`

### Step 6 — User Deploys VIEW & Imports to Power BI
**→ User:**
1. Reviews generated VIEW DDL (optional; copy-paste into SSMS for syntax validation)
2. Deploys: paste into SQL Server Management Studio or run with `-Execute` flag on script
3. Connects Power BI (DirectQuery or Import) to `[dbo].[TableName_DQ_Audit]`
4. Creates exceptions page: filter `RowHasIssues = 1`, display `IssueList`, bind colors to `MaxSeverity`

### Step 7 — Validation (Final Check)
**→ User verifies in Power BI:**
- Exceptions page shows only rows with issues (`RowHasIssues = 1`)
- `IssueList` column displays readable flag names (e.g., `"LoanID_IsBlank; Amount_OutOfRange"`)
- `MaxSeverity` colors render correctly (e.g., red for Error, orange for Warn)
- Drill-through works (via PK columns passed through VIEW)

---

## Output Contract (Always Produce)

### A) Rules CSV (Step 2 — Auto-generated)
- File: `documents/dq_rules.generated.csv`
- Schema: 14 columns (RuleId, TableName, ColumnName, RuleType, ExpectedType, AllowBlank, MinValue, MaxValue, AllowedValues, RefTable, RefColumn, ConditionSQL, Severity, Notes)
- Rows: auto-populated per table + user edits (Step 3)
- Severity: Error (critical) | Warn (quality concern) | (Info optional — usually omitted)

### B) Audit VIEW DDL (Step 5 — Post-approval)
- Per table: `[dbo].[TableName_DQ_Audit]`
- Columns: all source columns + flag columns + `RowHasIssues` + `MaxSeverity` + `IssueList`
- Structure: `WITH Flags AS (SELECT src.*, flag expressions...) SELECT *, RowHasIssues CASE..., IssueList STUFF...`

### C) Power BI Integration (Step 6 — User action)
- DirectQuery or Import the `[dbo].[TableName_DQ_Audit]` VIEW
- DAX measures (same as PQ-first skill): `DQ - Invalid Rows`, `DQ - Invalid Rows %`, `DQ - Rules Coverage %`
- Report pages: Overview (KPI cards), Exceptions (table filtered to `RowHasIssues = 1`), Coverage (rule registry)
- Conditional formatting: use `MaxSeverity` color codes (Error = #D13438 red, Warn = #F7630C orange, None = #FFFFFF white)

---

## ⚠️ T-SQL Output Rules

### Flag Naming Convention (Standardized Polarity)
All flags use `1 = problem` (no mixed polarity):
- `IsBlank` = 1 → field is null or whitespace
- `IsDuplicate` = 1 → key count > 1 in table
- `IsInvalidNumber` = 1 → TRY_CAST to FLOAT fails and source NOT NULL
- `IsInvalidDate` = 1 → TRY_CAST to DATE fails and source NOT NULL
- `IsOutOfDomain` = 1 → value NOT in AllowedValues and source NOT NULL
- `IsOutOfRange` = 1 → value outside MinValue–MaxValue and source NOT NULL
- `IsMissingInDim` = 1 → FK not found in dimension and source NOT NULL
- `MaxSeverity` = 'Error' | 'Warn' | NULL (worst severity of triggered rules)
- `RowHasIssues` = 1 if ANY flag = 1

### ConditionSQL (Conditional Rules)
For rules that apply only under certain conditions, wrap the flag CASE in a condition:

```sql
-- Only validate Amount when Stage = 'Closed Won'
CASE 
    WHEN src.[Stage] = 'Closed Won'
    THEN (CASE WHEN TRY_CAST(src.[Amount] AS FLOAT) BETWEEN 100 AND 9999999 THEN 1 ELSE 0 END)
    ELSE 0  -- rule not applicable; pass
END AS [Amount_IsOutOfRange_WhenClosed]
```

See `references/sql-check-patterns.md` for complete examples.

### IssueList Pattern (Concatenated Semi-delimited)
Uses `STUFF` + `CASE` for readable issue concatenation (SQL Server 2012+):

```sql
NULLIF(STUFF(
    CASE WHEN [IsBlank]=1           THEN '; IsBlank'           ELSE '' END +
    CASE WHEN [IsDuplicate]=1       THEN '; IsDuplicate'       ELSE '' END +
    CASE WHEN [IsInvalidNumber]=1   THEN '; IsInvalidNumber'   ELSE '' END +
    CASE WHEN [IsOutOfDomain]=1     THEN '; IsOutOfDomain'     ELSE '' END,
    1, 2, ''),  -- strip leading '; '
'') AS IssueList
```

Result: `"IsBlank; IsDuplicate"` or NULL if no issues.

---

## Guardrails (Performance + Correctness)

- **VIEW vs Staging Table:** Default is VIEW (no storage overhead, live queries). For tables > 10M rows, consider materialized staging table + nonclustered index on `RowHasIssues = 1` (Phase 2 option).
- **Avoid row multiplication on RI checks:** Use `NOT EXISTS` (correlated subquery), not LEFT JOIN (which can duplicate rows). See Pitfall P1.
- **Window functions require CTE:** `COUNT(*) OVER (PARTITION BY ...)` cannot be in WHERE clause of same query level. CTE is mandatory. See Pitfall P6.
- **Always alias source as `src`:** Use `src.*` in CTE; reference all source columns with `src.` prefix for safety.
- **Null handling in flags:** All flags return 0 when source is NULL (passes all checks). Explicitly check `src.[Col] IS NOT NULL` if you want to flag nulls as issues.
- **Collation sensitivity:** `IN (N'A', N'B')` uses Unicode literal prefix `N'` for NVARCHAR safety. Adjust for your collation.
- **Indexing:** If querying the audit VIEW repeatedly in Power BI, ask DBA to create nonclustered index on source table's PK + frequently filtered columns (e.g., `RowHasIssues`, `MaxSeverity`).

---

## Common Pitfalls

### P1 — Row Multiplication on RI Checks
**Wrong** (LEFT JOIN can duplicate rows if FK is not unique in dimension):
```sql
LEFT JOIN [dbo].[Dim] ON src.[FK] = [Dim].[Key]
...
[FK_IsMissingInDim] = CASE WHEN [Dim].[Key] IS NULL THEN 1 ELSE 0 END
```
**Correct** (NOT EXISTS avoids duplication):
```sql
[FK_IsMissingInDim] = CASE WHEN NOT EXISTS (SELECT 1 FROM [dbo].[Dim] WHERE [Key] = src.[FK]) AND src.[FK] IS NOT NULL THEN 1 ELSE 0 END
```

### P2 — STUFF Handling NULL
**Wrong** (STUFF returns NULL if input is empty string):
```sql
STUFF('' + '', 1, 2, '') -- returns NULL
```
**Correct** (wrap outer STUFF in NULLIF):
```sql
NULLIF(STUFF('' + '', 1, 2, ''), '') -- returns NULL
-- But STUFF('X'+''+'Y', 1, 2, '') returns 'Y'
```

### P3 — TRY_CAST vs CAST
**Wrong** (CAST fails on non-numeric):
```sql
CAST([Amount] AS FLOAT) -- error on invalid input
```
**Correct** (TRY_CAST returns NULL on failure, 1 = problem):
```sql
TRY_CAST([Amount] AS FLOAT) -- NULL on invalid
CASE WHEN TRY_CAST([Amount] AS FLOAT) IS NULL THEN 1 ELSE 0 END
```

### P4 — Whitespace in Blank Check
**Wrong** (spaces are not null):
```sql
CASE WHEN [Col] IS NULL THEN 1 ELSE 0 END
```
**Correct** (trim and check):
```sql
CASE WHEN [Col] IS NULL OR LTRIM(RTRIM(CAST([Col] AS NVARCHAR(MAX)))) = '' THEN 1 ELSE 0 END
```

### P5 — Column Name Collision with Source Table
**Wrong** (if FactLoan already has a column named `RowHasIssues`):
```sql
WITH Flags AS (
    SELECT src.*, ... AS RowHasIssues
)
-- "RowHasIssues" is ambiguous; duplicate column
```
**Correct** (check source schema first; rename output):
```sql
-- Add detection to Generate-DQRulesCSV.ps1:
-- IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'FactLoan' AND COLUMN_NAME = 'RowHasIssues')
--   THROW 50001, 'RowHasIssues already exists in source table. Rename in VIEW output.', 1;

-- In VIEW, if collision detected, rename to [DQ_RowHasIssues]:
SELECT *, ... AS [DQ_RowHasIssues]
```

### P6 — Window Functions in WHERE Clause
**Wrong** (window function can't be in WHERE in same query level):
```sql
WITH Flags AS (
    SELECT src.*,
        MCount = COUNT(*) OVER (PARTITION BY src.[Key])
    FROM [dbo].[Table] AS src
    WHERE COUNT(*) OVER (...) > 1  -- ERROR
)
```
**Correct** (CTE, then filter in outer query):
```sql
WITH Flags AS (
    SELECT src.*,
        MCount = COUNT(*) OVER (PARTITION BY src.[Key])
    FROM [dbo].[Table] AS src
)
SELECT *
FROM Flags
WHERE MCount > 1  -- OK now
```

### P7 — NULL in AllowedValues Domain Check
**Wrong** (NULL not in IN list):
```sql
[Status_IsOutOfDomain] = CASE WHEN [Status] IN (N'A', N'B', N'C') THEN 0 ELSE 1 END
-- NULL IN (...) is always NULL, not TRUE/FALSE
```
**Correct** (exclude NULL from domain):
```sql
[Status_IsOutOfDomain] = CASE WHEN [Status] IN (N'A', N'B', N'C') OR [Status] IS NULL THEN 0 ELSE 1 END
-- Or, if NULL should fail domain check:
[Status_IsOutOfDomain] = CASE WHEN [Status] IS NULL THEN 1 WHEN [Status] IN (N'A', N'B', N'C') THEN 0 ELSE 1 END
```

### P8 — ISNUMERIC Behavior in Older SQL Server
**Wrong** (ISNUMERIC accepts `$`, `-`, scientific notation):
```sql
CASE WHEN ISNUMERIC([Amount]) = 1 THEN 1 ELSE 0 END
-- ISNUMERIC('$100') = 1 ✓ but TRY_CAST might fail
```
**Correct** (SQL Server 2012+):
```sql
CASE WHEN TRY_CAST([Amount] AS FLOAT) IS NOT NULL THEN 1 ELSE 0 END
```

### P9 — Missing Severity in Approved CSV
If user approves CSV missing `Severity` column, the `Generate-DQAuditView.ps1` script will fail to compute `MaxSeverity`. Always validate CSV before execution:
```powershell
# In script: Check that CSV has exactly 14 columns including Severity
if (-not ($headers -contains 'Severity')) { Throw 'Severity column missing' }
```

### P10 — Power BI DirectQuery Performance on Large Audit VIEW
If `[dbo].[FactLoan_DQ_Audit]` is queried thousands of times per Power BI page load, it can be slow. Recommend:
- Create nonclustered index on source table: `ON [FactLoan] ([LoanID]) WITH (FILLFACTOR=80)`
- Or materialize to staging table: `SELECT * INTO [dbo].[FactLoan_DQ_Audit_Staging] FROM [dbo].[FactLoan_DQ_Audit]` + schedule refresh via SQL job

---

## Files in This Skill

- `SKILL.md` (this file — orchestrator instructions)
- **References:**
  - `references/dq-rules-schema.md` — 14-column CSV schema with SQL annotations
  - `references/sql-check-patterns.md` — T-SQL CASE patterns for each rule type
  - `references/report-layout.md` — Power BI integration (DirectQuery, Import, DAX measures)
  - `references/interaction-playbook.md` — agent workflow + MCP branching logic
- **Scripts:**
  - `scripts/Generate-DQRulesCSV.ps1` — schema inspection → CSV generation
  - `scripts/Generate-DQAuditView.ps1` — CSV → T-SQL VIEW DDL
- **Examples:**
  - `examples/example-input.md` — sample user prompt
  - `examples/dq_rules.example.csv` — sample FactLoan rules
  - `examples/example-sql-fact-loans.md` — full walkthrough from rules → VIEW → Power BI

