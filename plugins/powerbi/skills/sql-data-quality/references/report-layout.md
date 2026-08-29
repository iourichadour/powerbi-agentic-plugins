# Power BI Integration — Report Layout + Measures

## Overview

The SQL audit VIEW (`[dbo].[FactLoan_DQ_Audit]`) is imported into Power BI as a dataset table. This page describes report design patterns, DAX measures, and conditional formatting to surface data quality issues to end users.

---

## Connection Modes

### DirectQuery (Recommended for Large Tables)
**Setup:**
1. In Power BI Desktop: "Get Data" → SQL Server → ServerInstance + Database
2. Navigate to `[dbo].[FactLoan_DQ_Audit]`
3. Select "DirectQuery" mode (not Import)
4. Load into data model

**Pros:**
- Live view of latest data; no refresh lag
- Scales to 100M+ rows (Power BI handles query pushdown)
- No storage cost in Power BI Premium

**Cons:**
- Requires indexed source table for performance
- Cannot use calculated columns (DAX not pushed down to SQL)
- Slicers may be slower

### Import (Recommended for Scheduled Refreshes)
**Setup:**
1. In Power BI Desktop: "Get Data" → SQL Server → ServerInstance + Database
2. Navigate to `[dbo].[FactLoan_DQ_Audit]`
3. Select "Import" mode
4. Schedule refresh in Power BI Service (via gateway or direct connection)

**Pros:**
- Instant slicer / filter response
- Can use DAX measures, calculated columns
- Works without SQL connectivity at query time

**Cons:**
- Stored in Power BI dataset (storage cost)
- Refresh latency (hourly/daily, not real-time)
- Must schedule / manage refreshes

---

## DAX Measures (Identical to PQ-first Skill)

Place these measures in a new `DQ Measures` table for organization. All reference pre-computed flag columns from the audit VIEW.

### Measure 1 — Invalid Rows
```DAX
DQ - Invalid Rows = 
CALCULATE(
    COUNTROWS(FactLoan_DQ_Audit),
    FactLoan_DQ_Audit[RowHasIssues] = 1
)
```

### Measure 2 — Invalid Rows %
```DAX
DQ - Invalid Rows % = 
DIVIDE(
    [DQ - Invalid Rows],
    COUNTROWS(FactLoan_DQ_Audit)
)
```

### Measure 3 — Invalid by Rule Type (Optional Detail Measure)
```DAX
DQ - Invalid Rules Count = 
CALCULATE(
    COUNTROWS(DQ_Rules),
    FILTER(
        DQ_Rules,
        [RuleType] IN {"KeyNotBlank", "KeyUnique", "RI"}  -- critical rules
    )
)
```

### Measure 4 — Rules Coverage % (Requires DQ_Rules Table)
Import `dq_rules.generated.csv` as a separate table `DQ_Rules`:
```DAX
DQ - Rules Coverage % = 
DIVIDE(
    COUNTROWS(
        FILTER(
            NATURALLEFTOUTERJOIN(
                DQ_Rules,
                SELECTCOLUMNS(
                    INFO.COLUMNS(),
                    "TableName", [Table],
                    "ColumnName", [Name]
                )
            ),
            [ColumnName] <> BLANK()
        )
    ),
    COUNTROWS(DQ_Rules)
)
```

---

## Report Pages

### Page 1 — DQ Overview

**Layout:**
- Row 1: KPI cards (4 cards):
  - `Invalid Rows` (count)
  - `Invalid Rows %` (% formatting)
  - `MaxSeverity = Error` (count of Error rows)
  - `MaxSeverity = Warn` (count of Warn rows)
- Row 2: Clustered bar chart — Invalid rows by `TableName` (if multiple tables) or by `RuleType` (1 table)
- Row 3: Matrix — Rows: `RuleType`, Columns: `Severity`, Values: `COUNTROWS()` (shows distribution)

**Filters:**
- Optional date slicer (if audit VIEW has a load date column)

---

### Page 2 — Exceptions (Mandatory Filter Page)

**Purpose:** Drill into individual bad records with full context.

**Layout:**
- Row 1: Page-level filter: `RowHasIssues = 1` (hardcoded; not slicer)
- Row 2: Table visual with these columns (left-aligned):
  - PK column(s): `LoanID`, `AssetID` (for drill-through identification)
  - `IssueList` (readable issue description; e.g., "LoanID_IsBlank; CommitmentBalance_IsOutOfRange")
  - `MaxSeverity` (formatted: Error = red, Warn = orange, None = white)
  - Business key columns: `LoanName`, `Originator`, `CommitmentBalance`, `GLDate`, `Stage` (5–8 columns for context)
  - Audit columns: `[RowID]` if available (for traceability)
- Row 3: Optional detail visual (e.g., KPI card showing row count of exceptions)

**Conditional Formatting:**
Apply to `MaxSeverity` column:
- Value: Red (#D13438) when = "Error"
- Value: Orange (#F7630C) when = "Warn"  
- Value: White (#FFFFFF) when = NULL

**Drill-through (Optional):**
- From exceptions table, drill-through to detail page showing all columns for that LoanID
- Useful for root-cause analysis

---

### Page 3 — Rule Coverage

**Purpose:** Governance view — which tables/columns have rules; which gaps exist.

**Layout:**
- Row 1: Matrix visual:
  - Rows: `TableName`
  - Columns: `RuleType` (KeyNotBlank, KeyUnique, TypeNumber, etc.)
  - Values: Count of rules per table + type
- Row 2: Optional KPI: "Total Rules Deployed" (count of approved rules in CSV)
- Row 3: Optional KPI: "Model Coverage %" (ratio of rule-covered columns to total model columns)

**Data source:**
- Use `DQ_Rules` table (imported CSV) + optional join to `INFO.COLUMNS()` for coverage gap analysis
- Highlight missing rules (columns with no DQ checks)

---

## Recommended Color Scheme

| Severity | Hex Color | Usage |
|----------|-----------|-------|
| Error | #D13438 | High-priority issues; require immediate fix |
| Warn | #F7630C | Medium-priority quality concerns; monitor/batch fixes |
| None / OK | #FFFFFF | No issues; passes all checks |

Apply to:
- `MaxSeverity` column in Exceptions page (conditional formatting)
- Background color on business key columns (optional; if using `DQ_{FieldName}_BackgroundColor` DAX measures from dax-data-quality skill)

---

## Performance Tips

1. **DirectQuery Performance:**
   - Ensure source table has nonclustered index on PK + frequently filtered columns (e.g., `RowHasIssues`)
   - Avoid slicers on high-cardinality columns (e.g., `LoanID`) in DirectQuery; use text search box instead

2. **Import Mode Performance:**
   - Schedule refresh during off-peak hours (midnight / early morning)
   - Refresh frequency: match business need (hourly for critical tables, daily for others)
   - Use incremental refresh if table is very large (100M+ rows)

3. **Report Responsiveness:**
   - Limit Exceptions page to 10K–50K rows (paginate or add filters for large tables)
   - Use aggregated Overview page for performance dashboards (KPI cards, not full tables)

---

## Integration with dax-data-quality Skill

If using BOTH `sql-data-quality` (SQL audit VIEW) and `dax-data-quality` (Power Query flags):
- `sql-data-quality` is for SQL Server tables (upstream validation)
- `dax-data-quality` is for Power Query staging tables (post-PQ, pre-semantic model)
- Measures are identical; use same report pages and color scheme for consistency
- DO NOT apply both skills to the same table (redundant; choose one)

