# Report Layout + Measures

## Measures
### Invalid Rows
```DAX
Invalid Rows =
CALCULATE(
    COUNTROWS(<Table>),
    <Table>[RowHasIssues] = TRUE()
)
```

### Invalid Rows %
```DAX
Invalid Rows % =
DIVIDE(
    [Invalid Rows],
    COUNTROWS(<Table>)
)
```

## Suggested Pages
### 1) DQ Overview
- Cards: Invalid Rows, Invalid Rows %, Duplicate Key Rows
- Matrix: TableName / ColumnName / RuleType (from DQ_Rules)

### 2) Exceptions
- Table visual bound to the base table(s)
- Page filter: RowHasIssues = TRUE()
- Show IssueList + key business columns
- Add drill-through by RowID or key

### 3) Rule Coverage
- Join DQ_Rules to Model_Columns to show:
  - columns with rules vs total
  - type mismatches (ExpectedType vs DataType)
