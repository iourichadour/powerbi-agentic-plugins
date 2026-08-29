# Interaction Playbook — Agent Behavior + MCP Branching

This playbook describes the agent's step-by-step interaction with the user, including optional MSSQL MCP branching for schema inspection.

---

## Step 0 — Confirm User Intent

**Agent prompt:**
```
"You're using the sql-data-quality skill to build a SQL Server audit VIEW.

This skill will:
1. Inspect your table schema
2. Auto-generate data quality rules in a CSV
3. ASK YOU TO REVIEW AND APPROVE the CSV (no auto-execution)
4. Generate T-SQL VIEW DDL after your approval
5. You deploy to SQL Server and import into Power BI

Ready to proceed? Provide: table name(s), SQL Server instance, database name."
```

---

## Step 1 — Gather User Input

**Agent collects:**
```
Q1. Which table(s) do you want to validate? (comma-separated)
    Example: FactLoan, FactPayment

Q2. SQL Server connection details:
    - Server instance (e.g., "LAPTOP\SQLEXPRESS" or "myserver.database.windows.net")
    - Database name (e.g., "MyDB")
    - Schema (default: "dbo")
    - Authentication: Windows or SQL credentials?

Q3. Any custom rules to add beyond auto-detected ones?
    (Save for Step 3 — can add after reviewing generated CSV)
```

**User response example:**
```
Table: FactLoan
Instance: localhost
Database: AscentDB
Schema: dbo
Auth: Windows
```

---

## Step 2 — Attempt Schema Inspection (MCP or Fallback)

### MCP Path (if MSSQL tools available)

**Agent checks:** "Is MSSQL MCP available?"
- If YES → proceed to **MCP Sub-steps A–C** below
- If NO → proceed to **Fallback Path** below

### MCP Sub-step A — Query INFORMATION_SCHEMA.COLUMNS

Run via MCP tool (`<!-- MCP_TOOL_NAME: mssql/execute_query -->`):
```sql
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    ORDINAL_POSITION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'FactLoan'
ORDER BY ORDINAL_POSITION
```

**Agent displays:** Column list with types (e.g., "LoanID (nvarchar), CommitmentBalance (float), GLDate (date), Stage (nvarchar), OriginatorID (int)")

### MCP Sub-step B — Query KEY_COLUMN_USAGE + TABLE_CONSTRAINTS

Run via MCP:
```sql
SELECT 
    tc.TABLE_NAME,
    tc.CONSTRAINT_NAME,
    tc.CONSTRAINT_TYPE,  -- PRIMARY KEY, FOREIGN KEY, UNIQUE
    kcu.COLUMN_NAME
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
LEFT JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu 
    ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
WHERE tc.TABLE_SCHEMA = 'dbo' AND tc.TABLE_NAME = 'FactLoan'
```

**Agent extracts:**
- PK columns → propose `KeyNotBlank`, `KeyUnique` rules (Severity: Error)
- FK columns → propose `RI` rules (Severity: Error)

### MCP Sub-step C — Query REFERENTIAL_CONSTRAINTS + Sample Cardinality

Run via MCP:
```sql
SELECT 
    fk.CONSTRAINT_NAME,
    fk.TABLE_NAME,
    fk.COLUMN_NAME,
    fk.REFERENCED_TABLE_NAME,
    fk.REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
...
```

Plus cardinality sampling for low-cardinality columns:
```sql
SELECT TOP 50 DISTINCT [Stage] FROM [dbo].[FactLoan] ORDER BY [Stage]
```

**Agent uses:**
- Cardinality < 20 → suggest `Domain` rule with AllowedValues auto-populated from TOP 50 DISTINCT
- Numeric columns → suggest `TypeNumber` + `Range` (with sensible bounds: 0 to 1M for Amount, -180 to 180 for coordinates, etc.)
- Date columns → suggest `TypeDate`
- Text columns → suggest `KeyNotBlank` if non-nullable

### Fallback Path (no MCP)

**Agent prompt:**
```
"MSSQL MCP not available. I'll prompt you for table schema instead.

List the columns you want to validate:
Format: ColumnName | DataType | Nullable | IsPrimaryKey | IsForeignKey | RefTable.RefColumn

Example:
LoanID | TEXT | No | Yes | No
CommitmentBalance | FLOAT | Yes | No | No
GLDate | DATE | Yes | No | No
Stage | TEXT | Yes | No | No
OriginatorID | INT | No | No | Yes | DimOriginator.OriginatorID
"
```

**User provides list; agent parses and applies same pattern-matching logic (no SQL queries, but same heuristics).**

---

## Step 3 — Generate CSV Rules (Programmatic)

**Agent runs or simulates:** `Generate-DQRulesCSV.ps1` (or equivalent logic)

**Input:** Column list from Step 2 (MCP or fallback) + user's confirmed table/column selection

**Algorithm:**
1. For each column in table:
   - If PK → emit `{TableName}_{ColumnName}_KeyNotBlank` (RuleType: KeyNotBlank, Severity: Error)
   - If PK → emit `{TableName}_{ColumnName}_KeyUnique` (RuleType: KeyUnique, Severity: Error)
   - If FK (via REFERENTIAL_CONSTRAINTS or user input) → emit `{TableName}_{ColumnName}_RI` (RuleType: RI, Severity: Error, RefTable/RefColumn set)
   - If DATA_TYPE IN ('float', 'int', 'decimal', 'numeric') → emit `TypeNumber` rule (Severity: Warn)
   - If DATA_TYPE IN ('date', 'datetime', 'datetime2') → emit `TypeDate` rule (Severity: Warn)
   - If DATA_TYPE IN ('varchar', 'nvarchar', 'char') AND estimated cardinality < 20 → emit `Domain` rule with AllowedValues from TOP 50 DISTINCT (Severity: Warn)
   - If DATA_TYPE IN ('float', 'int', 'decimal') → emit optional `Range` rule with sensible bounds (Severity: Warn)
   - If IS_NULLABLE = 'No' AND DATA_TYPE IN ('varchar', 'nvarchar') → emit optional `KeyNotBlank` rule (Severity: Warn)

2. Output CSV with all 14 columns:
   - RuleId, TableName, ColumnName, RuleType, ExpectedType, AllowBlank, MinValue, MaxValue, AllowedValues, RefTable, RefColumn, ConditionSQL, Severity, Notes
   - Save to `documents/dq_rules.generated.csv`

**Agent displays CSV (as table in chat):**
```
| RuleId | TableName | ColumnName | RuleType | Severity | AllowedValues | Notes |
|--------|-----------|------------|----------|----------|--------------|-------|
| FD_LoanID_KeyNotBlank | FactLoan | LoanID | KeyNotBlank | Error | | Auto-detected: PK |
| FD_LoanID_KeyUnique | FactLoan | LoanID | KeyUnique | Error | | Auto-detected: PK duplicate check |
| FD_Amount_TypeNumber | FactLoan | CommitmentBalance | TypeNumber | Warn | | Auto-detected: numeric column |
| FD_Amount_Range | FactLoan | CommitmentBalance | Range | Warn | 1|999999999 | Auto-detected: typical bounds |
| FD_GLDate_TypeDate | FactLoan | GLDate | TypeDate | Warn | | Auto-detected: date column |
| FD_Stage_Domain | FactLoan | Stage | Domain | Warn | Prospecting|Approved|Closed Won | Auto-detected: 3 values in cardinality sample |
| FD_OriginatorID_RI | FactLoan | OriginatorID | RI | Error | DimOriginator.OriginatorID | Auto-detected: FK |
```

---

## Step 4 — Present CSV to User for Review

**Agent prompt:**
```
"Generated 7 validation rules for FactLoan:

SUMMARY:
  - Error (critical): 3 rules (KeyNotBlank, KeyUnique, RI)
  - Warn (quality): 4 rules (TypeNumber, Range, TypeDate, Domain)

Review the CSV above. You can:
  1. APPROVE — "looks good, proceed"
  2. EDIT — "modify row X: change Severity to Warn", "delete Domain rule", etc.
  3. ADD CUSTOM — paste new CSV rows

What would you like to do?"
```

**User options:**
- If "approve" → **go to Step 4b (Approval Gate)**
- If "edit" / "add" → Agent updates CSV, re-displays, loops back to "What would you like to do?"

---

## Step 4b — APPROVAL GATE (Mandatory Confirmation)

**CRITICAL GATE — No auto-execution.**

**Agent prompt:**
```
✓ APPROVAL REQUIRED

I'm ready to generate T-SQL audit VIEW for FactLoan with these 7 rules.

Once you approve, I will:
1. Generate CREATE OR ALTER VIEW DDL
2. Provide it for review (no auto-deployment)
3. You paste into SQL Server or run with -Execute flag

CONFIRM: Approve these 7 validation rules? (Yes/No)
```

**User responds:**
- If **"Yes"** → proceed to **Step 5** (VIEW generation)
- If **"No"** or **"Modify"** → loop back to Step 3 (CSV edit)
- If **"Cancel"** → quit skill execution

**DO NOT proceed beyond this gate without explicit "Yes".**

---

## Step 5 — Post-Approval: Generate VIEW DDL

**Agent runs or simulates:** `Generate-DQAuditView.ps1`

**Input:** Approved `documents/dq_rules.generated.csv`

**Process:**
1. For each rule row in CSV:
   - Switch on RuleType
   - Emit appropriate CASE expression (pattern from `sql-check-patterns.md`)
   - Substitute ColumnName, MinValue, MaxValue, AllowedValues, RefTable, RefColumn, ConditionSQL
2. Build `RowHasIssues` combiner: all flags = 1 in OR-chain
3. Build `MaxSeverity` CASE: prioritize Error > Warn > NULL
4. Build `IssueList` STUFF+CASE concatenation
5. Wrap in `CREATE OR ALTER VIEW [dbo].[FactLoan_DQ_Audit] AS WITH Flags AS (...)`
6. Output complete T-SQL DDL

**Agent displays DDL (in fenced code block):**
```sql
CREATE OR ALTER VIEW [dbo].[FactLoan_DQ_Audit] AS
WITH Flags AS (
    SELECT
        src.*,
        CASE WHEN src.[LoanID] IS NULL OR ... THEN 1 ELSE 0 END AS [LoanID_IsBlank],
        ...
    FROM [dbo].[FactLoan] AS src
)
SELECT *, ... AS RowHasIssues, ... AS MaxSeverity, ... AS IssueList
FROM Flags;
GO
```

**Agent offers options:**
```
VIEW DDL is ready. Next steps:

A) Copy-paste DDL into SQL Server Management Studio and run
B) Have me deploy directly via PowerShell -Execute flag (if credentials provided)
C) Save to a .sql file for later

Which would you prefer? (Or just copy from above block.)
```

---

## Step 6 — User Deploys & Imports to Power BI

**Agent provides guidance:**
```
1. **Deploy to SQL Server:**
   - Option A: Paste DDL into SSMS Query Editor → Execute
   - Option B: powershell ... -Execute -ServerInstance "localhost" -Database "AscentDB"

2. **Verify VIEW in SQL Server:**
   SELECT * FROM [dbo].[FactLoan_DQ_Audit] WHERE RowHasIssues = 1 LIMIT 10

3. **Import into Power BI:**
   - Power BI Desktop → Get Data → SQL Server
   - Select [dbo].[FactLoan_DQ_Audit]
   - Choose DirectQuery (live) or Import (scheduled refresh)
   - Add to data model

4. **Create Report Pages** (see references/report-layout.md):
   - Overview page (KPI cards)
   - Exceptions page (table filtered to RowHasIssues = 1)
   - Coverage page (rule registry)

5. **Optional: Add DAX Measures** (from references/report-layout.md)
```

---

## Step 7 — Validation Checkpoint

**Agent option (if user shares Power BI/SQL output):**
```
"Share a screenshot or query result:
- SQL: SELECT COUNT(*) as ExceptionCount FROM [dbo].[FactLoan_DQ_Audit] WHERE RowHasIssues = 1
- Power BI: Row count of Exceptions page

This helps verify the VIEW is working correctly."
```

**If exceptions found:** Agent discusses root causes and may suggest rule adjustments.

---

## MCP Tool Reference

<!-- MCP_TOOL_NAME: mssql/execute_query -->

When MSSQL MCP is available, the skill uses:
- **Tool:** `mssql_schema_designer` or `mssql_dab` or direct query execution tool
- **Queries:**
  - `INFORMATION_SCHEMA.COLUMNS` (schema inspection)
  - `INFORMATION_SCHEMA.KEY_COLUMN_USAGE` + `TABLE_CONSTRAINTS` (PK/FK detection)
  - `INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS` (FK metadata)
  - `SELECT TOP 50 DISTINCT [Col]` (cardinality sampling)
- **Fallback:** If MCP unavailable, ask user for column list manually

To update MCP tool name, search for `<!-- MCP_TOOL_NAME: ... -->` and replace with your system's MSSQL tool name.

