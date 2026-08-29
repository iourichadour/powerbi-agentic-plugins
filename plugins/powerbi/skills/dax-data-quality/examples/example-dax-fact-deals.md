# Example DAX — Fact_Deals

> This example shows both raw DAX (for DAX Studio / Tabular Editor) and the equivalent TMDL blocks (for PBIP `.tmdl` files). Always use the TMDL format when editing files in a PBIP project.

## Inventory tables (once per model)

**TMDL — `definition/tables/Model_Columns.tmdl`:**
```tmdl
table Model_Columns
	lineageTag: <new-guid>

	column TableName
		dataType: string
		summarizeBy: none
		sourceColumn: TableName

	column ColumnName
		dataType: string
		summarizeBy: none
		sourceColumn: ColumnName

	column DataType
		dataType: int64
		summarizeBy: none
		sourceColumn: DataType

	column IsHidden
		dataType: boolean
		summarizeBy: none
		sourceColumn: IsHidden

	partition Model_Columns = calculated
		mode: import
		source =
			SELECTCOLUMNS(
			    INFO.COLUMNS(),
			    "TableName", [Table],
			    "ColumnName", [Name],
			    "DataType", [DataType],
			    "IsHidden", [IsHidden]
			)
```
Then add `ref table Model_Columns` to `model.tmdl`.

---

## Fact_Deals calculated columns

**TMDL — inside `definition/tables/Fact_Deals.tmdl`** (add after existing columns):

```tmdl
	column DealID_IsBlank
		dataType: boolean
		expression =
			ISBLANK(Fact_Deals[DealID]) || Fact_Deals[DealID] = ""
		displayFolder: DQ

	column DealID_IsDuplicate
		dataType: boolean
		expression =
			VAR k = Fact_Deals[DealID]
			RETURN
			IF(
			    ISBLANK(k) || k = "",
			    FALSE(),
			    CALCULATE(
			        COUNTROWS(Fact_Deals),
			        ALLEXCEPT(Fact_Deals, Fact_Deals[DealID])
			    ) > 1
			)
		displayFolder: DQ

	column Amount_IsValidNumber
		dataType: boolean
		expression =
			VAR v = Fact_Deals[Amount]
			RETURN
			IF(
			    ISBLANK(v),
			    FALSE(),
			    NOT ISERROR( VALUE(v) )
			)
		displayFolder: DQ

	column Amount_IsNonNegative
		dataType: boolean
		expression =
			VAR n = VALUE(Fact_Deals[Amount])
			RETURN
			NOT ISERROR(n) && n >= 0
		displayFolder: DQ

	column Stage_IsAllowed
		dataType: boolean
		expression =
			Fact_Deals[Stage] IN { "Prospecting", "Underwriting", "Approved", "Closed Won", "Closed Lost" }
		displayFolder: DQ

	column CustomerID_IsMissingInDim
		dataType: boolean
		expression =
			ISBLANK( RELATED(DimCustomer[CustomerID]) )
		displayFolder: DQ

	column RowHasIssues
		dataType: boolean
		expression =
			Fact_Deals[DealID_IsBlank]
			    || Fact_Deals[DealID_IsDuplicate]
			    || NOT Fact_Deals[Amount_IsValidNumber]
			    || NOT Fact_Deals[Amount_IsNonNegative]
			    || NOT Fact_Deals[Stage_IsAllowed]
			    || Fact_Deals[CustomerID_IsMissingInDim]
		displayFolder: DQ

	column IssueList
		dataType: string
		expression =
			VAR Issues =
			    FILTER(
			        UNION(
			            ROW("Issue", "DealID is blank",                    "Bad", Fact_Deals[DealID_IsBlank]),
			            ROW("Issue", "DealID is duplicate",                 "Bad", Fact_Deals[DealID_IsDuplicate]),
			            ROW("Issue", "Amount is not numeric",               "Bad", NOT Fact_Deals[Amount_IsValidNumber]),
			            ROW("Issue", "Amount is negative",                  "Bad", NOT Fact_Deals[Amount_IsNonNegative]),
			            ROW("Issue", "Stage not allowed",                   "Bad", NOT Fact_Deals[Stage_IsAllowed]),
			            ROW("Issue", "CustomerID missing in DimCustomer",   "Bad", Fact_Deals[CustomerID_IsMissingInDim])
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

---

## DQ_Rules_WithModelType calculated table

**TMDL — `definition/tables/DQ_Rules_WithModelType.tmdl`** (new file):
```tmdl
table DQ_Rules_WithModelType
	lineageTag: <new-guid>

	partition DQ_Rules_WithModelType = calculated
		mode: import
		source =
			NATURALLEFTOUTERJOIN(
			    DQ_Rules,
			    Model_Columns
			)
```
Add `ref table DQ_Rules_WithModelType` to `model.tmdl`.

---

## Standard DQ Measures (in `_Measures.tmdl`)

```tmdl
	measure 'DQ - Fact_Deals Invalid Rows' =
			CALCULATE(COUNTROWS(Fact_Deals), Fact_Deals[RowHasIssues] = TRUE())
		formatString: #,0
		displayFolder: Data Quality

	measure 'DQ - Fact_Deals Invalid Rows %' =
			DIVIDE([DQ - Fact_Deals Invalid Rows], COUNTROWS(Fact_Deals))
		formatString: 0.00%
		displayFolder: Data Quality

	measure 'DQ - Rules Coverage %' =
			DIVIDE(
			    COUNTROWS(FILTER(DQ_Rules, NOT ISBLANK(DQ_Rules[ExpectedType]))),
			    COUNTROWS(DQ_Rules)
			)
		formatString: 0.00%
		displayFolder: Data Quality
```

> ⚠️ `DQ - Rules Coverage %` requires `DQ_Rules[ExpectedType]` to exist. Verify this column is present in your `DQ_Rules` table before adding this measure.

