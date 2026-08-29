# dq_rules.csv — Rules Registry Schema

**Role in PQ-First DQ Framework:**  
This CSV is the **single source of truth for all validation rules** — both the per-row checks executed in Power Query and the aggregation logic in DAX. The registry remains central to **governance and audit** regardless of where flags are computed.

Use this CSV as the editable registry of data quality rules.

## Required columns
```csv
RuleId,TableName,ColumnName,RuleType,ExpectedType,AllowBlank,MinValue,MaxValue,AllowedValues,RefTable,RefColumn,ConditionDAX,Severity,Notes
```

> ⚠️ **`ExpectedType` is required.** The standard measure `DQ - Rules Coverage %` references `DQ_Rules[ExpectedType]` with `NOT ISBLANK(DQ_Rules[ExpectedType])`. If this column is missing from the imported table, that measure will error with "Column not found". Always include it — even if some rows leave it blank.

## Field meanings
- **RuleId**: unique identifier (e.g., `FD_DealID_KeyNotBlank`)
- **RuleType**: `KeyNotBlank | KeyUnique | TypeNumber | TypeDate | Range | Domain | RI | Custom`
- **ExpectedType**: Power BI model type label (e.g., `Text`, `Number`, `Date`, `Boolean`). Leave blank for rules where type checking is not applicable.
- **AllowedValues**: `|`-delimited list (e.g., `Prospecting|Approved|Closed Won`)
- **RefTable / RefColumn**: for referential integrity (RI) checks
- **ConditionDAX**: optional conditional rule applicability (e.g., `Fact_Deals[Stage] = "Closed Won"`)
- **Severity**: `Error | Warn`

## Authoring notes
- Keep the registry focused on **keys and critical fields** for performance.
- Use ConditionDAX for conditional rules instead of duplicating columns.
- When importing as "Enter Data" in Power BI Desktop, make sure **all 14 columns are present** — add empty columns if needed. Missing columns cause downstream measure failures.

---

## Usage in PQ-First DQ Framework

### Power Query (Per-Row Checks)
Use the registry to **drive M code generation**:
- **RuleType** → determine which pattern to apply (e.g., `KeyNotBlank` → blank detection, `Domain` → allowed-values check)
- **ColumnName** → which column to validate
- **ExpectedType**, **AllowedValues**, **MinValue**/**MaxValue**, **RefTable**/**RefColumn** → parameters for the M function

Example: Row in `dq_rules.csv`:
```
FD_Amount_Range,FactLoan,LoanAmount,Range,Number,,10000,5000000,,,,
```

Generates M code:
```m
Step_AmountInRange = Table.AddColumn(
  Source,
  "LoanAmount_IsInRange",
  each try (
    let amount = Value.FromText([LoanAmount])
    in if amount >= 10000 and amount <= 5000000 then 1 else 0
  ) otherwise 0,
  type number
)
```

See [pq-check-patterns.md](pq-check-patterns.md) for all M patterns and [example-pq-fact-loans.md](../examples/example-pq-fact-loans.md) for a complete walkthrough.

### DAX (Aggregation & Coverage)
The registry is **imported as the `DQ_Rules` table** in Power BI:
- Measures query `COUNTROWS(DQ_Rules)` to aggregate rule instances
- Joined to `Model_Columns` (via `INFO.COLUMNS()`) to compute `DQ - Rules Coverage %`
- Provides **drill-through context** in report exceptions

The registry is the **audit trail**; if a rule is added/removed, the CSV tracks it in version control.


