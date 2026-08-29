# DAX Check Patterns (Per Table)

> These patterns are for **calculated columns** in the target table.
>
> **TMDL Projects (PBIP):** Use the TMDL block format shown for each pattern — NOT the raw `Table[Column] = expr` syntax. Raw DAX assignment syntax only works in DAX Studio or Tabular Editor query windows.
>
> **TMDL rules**: tabs only, `column` keyword (never `calculatedColumn`), properties at depth 2, DAX body at depth 3.

## RowID
Prefer Power Query index. If not available, use a stable composite:

**Raw DAX (DAX Studio / Tabular Editor only):**
```DAX
RowID =
COMBINEVALUES(
    "|",
    <Table>[<Key1>],
    <Table>[<Key2>]
)
```

**TMDL format (use in `.tmdl` files):**
```tmdl
	column RowID
		dataType: string
		expression =
			COMBINEVALUES(
			    "|",
			    <Table>[<Key1>],
			    <Table>[<Key2>]
			)
		displayFolder: DQ
```

## Key checks
### Not blank
**Raw DAX:**
```DAX
<Key>_IsBlank =
ISBLANK(<Table>[<Key>]) || <Table>[<Key>] = ""
```
**TMDL:**
```tmdl
	column <Key>_IsBlank
		dataType: boolean
		expression =
			ISBLANK(<Table>[<Key>]) || <Table>[<Key>] = ""
		displayFolder: DQ
```

### Duplicate (single key)
**Raw DAX:**
```DAX
<Key>_IsDuplicate =
VAR k = <Table>[<Key>]
RETURN
IF(
    ISBLANK(k) || k = "",
    FALSE(),
    CALCULATE(
        COUNTROWS(<Table>),
        ALLEXCEPT(<Table>, <Table>[<Key>])
    ) > 1
)
```
**TMDL:**
```tmdl
	column <Key>_IsDuplicate
		dataType: boolean
		expression =
			VAR k = <Table>[<Key>]
			RETURN
			IF(
			    ISBLANK(k) || k = "",
			    FALSE(),
			    CALCULATE(
			        COUNTROWS(<Table>),
			        ALLEXCEPT(<Table>, <Table>[<Key>])
			    ) > 1
			)
		displayFolder: DQ
```

### Duplicate (composite key)
**Raw DAX:**
```DAX
CompositeKey =
COMBINEVALUES("|", <Table>[<Key1>], <Table>[<Key2>])

CompositeKey_IsDuplicate =
VAR k = <Table>[CompositeKey]
RETURN
IF(
    ISBLANK(k) || k = "",
    FALSE(),
    CALCULATE(
        COUNTROWS(<Table>),
        ALLEXCEPT(<Table>, <Table>[CompositeKey])
    ) > 1
)
```
**TMDL:** Apply same single-key TMDL pattern twice — once for `CompositeKey`, once for `CompositeKey_IsDuplicate`.

## Type checks (conversion-based)
### Numeric
```DAX
<Col>_IsValidNumber =
VAR v = <Table>[<Col>]
RETURN
IF(
    ISBLANK(v),
    FALSE(),
    NOT ISERROR( VALUE(v) )
)
```

### Date
```DAX
<Col>_IsValidDate =
VAR v = <Table>[<Col>]
RETURN
IF(
    ISBLANK(v),
    TRUE(),
    NOT ISERROR( DATEVALUE(v) )
)
```

## Range / Domain
### Range
```DAX
<Col>_IsInRange =
VAR n = VALUE(<Table>[<Col>])
RETURN
NOT ISERROR(n) && n >= <Min> && n <= <Max>
```

### Domain (allowed set)
```DAX
<Col>_IsAllowed =
<Table>[<Col>] IN { "A", "B", "C" }
```

## Referential Integrity (RI)
### With relationships
```DAX
<FK>_IsMissingInDim =
ISBLANK( RELATED(<DimTable>[<DimKey>]) )
```

### Without relationships
```DAX
<FK>_IsMissingInDim =
VAR fk = <Table>[<FK>]
RETURN
NOT CONTAINS(<DimTable>, <DimTable>[<DimKey>], fk)
```

## Rollups
### RowHasIssues
**Raw DAX:**
```DAX
RowHasIssues =
    <Table>[<Key>_IsBlank]
    || <Table>[<Key>_IsDuplicate]
    || NOT <Table>[<Col>_IsValidNumber]
    || <Table>[<FK>_IsMissingInDim]
```
**TMDL:**
```tmdl
	column RowHasIssues
		dataType: boolean
		expression =
			<Table>[<Key>_IsBlank]
			    || <Table>[<Key>_IsDuplicate]
			    || NOT <Table>[<Col>_IsValidNumber]
			    || <Table>[<FK>_IsMissingInDim]
		displayFolder: DQ
```

### IssueList
> ⚠️ This pattern is complex. Write each `ROW(...)` on its own line. After editing in TMDL, verify tab indentation — the body of `expression =` must be at depth 3 (three tabs from the left).

**Raw DAX:**
```DAX
IssueList =
VAR Issues =
    FILTER(
        UNION(
            ROW("Issue", "<Key> is blank", "Bad", <Table>[<Key>_IsBlank]),
            ROW("Issue", "<Key> is duplicate", "Bad", <Table>[<Key>_IsDuplicate]),
            ROW("Issue", "<Col> not numeric", "Bad", NOT <Table>[<Col>_IsValidNumber]),
            ROW("Issue", "<FK> missing in <DimTable>", "Bad", <Table>[<FK>_IsMissingInDim])
        ),
        [Bad] = TRUE()
    )
RETURN
IF(
    COUNTROWS(Issues) = 0,
    BLANK(),
    CONCATENATEX(Issues, [Issue], "; ")
)
```
**TMDL:**
```tmdl
	column IssueList
		dataType: string
		expression =
			VAR Issues =
			    FILTER(
			        UNION(
			            ROW("Issue", "<Key> is blank",         "Bad", <Table>[<Key>_IsBlank]),
			            ROW("Issue", "<Key> is duplicate",      "Bad", <Table>[<Key>_IsDuplicate]),
			            ROW("Issue", "<Col> not numeric",       "Bad", NOT <Table>[<Col>_IsValidNumber]),
			            ROW("Issue", "<FK> missing in <Dim>",   "Bad", <Table>[<FK>_IsMissingInDim])
			        ),
			        [Bad] = TRUE()
			    )
			RETURN
			IF(
			    COUNTROWS(Issues) = 0,
			    BLANK(),
			    CONCATENATEX(Issues, [Issue], "; ")
			)
		displayFolder: DQ
		summarizeBy: none
```

