# Example: Power Query–First DQ Framework for FactLoan

This example walks through a **complete DQ framework implementation** for the **Green Light Status** project's FactLoan table, moving per-row checks to Power Query and keeping aggregation in DAX.

---

## Context: Green Light Status FactLoan

**Target table:** FactLoan (loan origination fact table)  
**Key column:** LoanID (composite with AssetID for duplicate detection)  
**Critical fields:** LoanAmount, OriginationDate, ApprovalStatus, PropertyType  
**Foreign keys:** PropertyID → DimProperty, ProductID → DimProduct

---

## Step 1 — Import Rules Registry into Semantic Model

The `DQ_Rules` table becomes the **single source of truth** for all validation rules. This table drives both Power Query checks and DAX measures.

### Create the DQ_Rules Query (Inline JSON)

Define all validation rules as an inline JSON string embedded directly in Power Query. This approach works in both **Power BI Desktop and Power BI Service** — no file dependencies.

Create a new blank query named `DQ_Rules` and paste the following into the Advanced Editor:

```m
let
  RawJson =
    "{
      ""dq_rules"": [
        {
          ""id"": 1, ""table_name"": ""FactLoan"", ""column_name"": ""LoanID"",
          ""rule_type"": ""Blank"", ""rule_name"": ""LoanID_IsBlank"",
          ""rule_definition"": ""Key cannot be null or empty"",
          ""expected_type"": ""string"", ""allowed_values"": null,
          ""min_value"": null, ""max_value"": null
        },
        {
          ""id"": 2, ""table_name"": ""FactLoan"", ""column_name"": ""LoanID"",
          ""rule_type"": ""Duplicate"", ""rule_name"": ""LoanID_IsDuplicate"",
          ""rule_definition"": ""Single LoanID per row"",
          ""expected_type"": ""string"", ""allowed_values"": null,
          ""min_value"": null, ""max_value"": null
        },
        {
          ""id"": 3, ""table_name"": ""FactLoan"", ""column_name"": ""LoanAmount"",
          ""rule_type"": ""Type"", ""rule_name"": ""Amount_IsValidNumber"",
          ""rule_definition"": ""Must parse as number"",
          ""expected_type"": ""number"", ""allowed_values"": null,
          ""min_value"": null, ""max_value"": null
        },
        {
          ""id"": 4, ""table_name"": ""FactLoan"", ""column_name"": ""LoanAmount"",
          ""rule_type"": ""Range"", ""rule_name"": ""Amount_IsInRange"",
          ""rule_definition"": ""Between 10000 and 5000000"",
          ""expected_type"": ""number"", ""allowed_values"": null,
          ""min_value"": 10000, ""max_value"": 5000000
        },
        {
          ""id"": 5, ""table_name"": ""FactLoan"", ""column_name"": ""OriginationDate"",
          ""rule_type"": ""Type"", ""rule_name"": ""Date_IsValidDate"",
          ""rule_definition"": ""Must parse as date (MM/DD/YYYY)"",
          ""expected_type"": ""date"", ""allowed_values"": null,
          ""min_value"": null, ""max_value"": null
        },
        {
          ""id"": 6, ""table_name"": ""FactLoan"", ""column_name"": ""ApprovalStatus"",
          ""rule_type"": ""Domain"", ""rule_name"": ""Status_IsAllowed"",
          ""rule_definition"": ""One of: Approved | Pending | Rejected | Withdrawn"",
          ""expected_type"": ""string"",
          ""allowed_values"": ""Approved|Pending|Rejected|Withdrawn"",
          ""min_value"": null, ""max_value"": null
        },
        {
          ""id"": 7, ""table_name"": ""FactLoan"", ""column_name"": ""PropertyID"",
          ""rule_type"": ""RI"", ""rule_name"": ""PropertyID_IsMissingInDim"",
          ""rule_definition"": ""Must exist in DimProperty"",
          ""expected_type"": ""string"", ""allowed_values"": null,
          ""min_value"": null, ""max_value"": null
        },
        {
          ""id"": 8, ""table_name"": ""FactLoan"", ""column_name"": ""ProductID"",
          ""rule_type"": ""RI"", ""rule_name"": ""ProductID_IsMissingInDim"",
          ""rule_definition"": ""Must exist in DimProduct"",
          ""expected_type"": ""string"", ""allowed_values"": null,
          ""min_value"": null, ""max_value"": null
        }
      ]
    }",
  Source = Json.Document(Text.ToBinary(RawJson)),
  Rules = Table.FromRecords(Source[dq_rules])
in
  Rules
```

**Why this approach:**
- Works in **Power BI Service** — no file system access required
- Rules are **embedded in the query itself**, version-controlled with the PBIP project
- `Json.Document(Text.ToBinary(...))` parses the inline string identically to reading a file
- Double-quoted strings (`""`) are M's escape syntax for literal `"` inside a text value

**Steps:**
1. In **Power Query Editor**, select **New Query** → **Blank Query**
2. Open **Advanced Editor**
3. Paste the M code above
4. Name the query `DQ_Rules`
5. **Close & Apply** — the table is now in the model

**To update rules:** Edit the JSON string directly in the Advanced Editor and refresh.

### Result: DQ_Rules Table in Semantic Model

After importing and converting the JSON, the `DQ_Rules` table is loaded in your semantic model with columns:

| Column | Type | Purpose |
|--------|------|---------|
| `id` | Integer | Unique rule identifier |
| `table_name` | Text | Target table (e.g., "FactLoan") |
| `column_name` | Text | Target column (e.g., "LoanID", "LoanAmount") |
| `rule_type` | Text | Type of check (Blank, Duplicate, Type, Range, Domain, RI) |
| `rule_name` | Text | Check column name to create in PQ (e.g., "LoanID_IsBlank") — **must match PQ column** |
| `rule_definition` | Text | Human-readable rule description |
| `expected_type` | Text | Data type expected (required for DAX coverage measures) |
| `allowed_values` | Text | Pipe-separated list for domain checks (e.g., "Approved\|Pending\|Rejected") |
| `min_value` | Number | Lower bound for range checks |
| `max_value` | Number | Upper bound for range checks |

**Key column:** `rule_name` — must exactly match the PQ flag column name created in Step 2. This is how `DQ_Rules_WithModelType` will join rules to implemented columns.

---

## Step 2 — Add DQ Check Columns in Power Query (Driven by DQ_Rules)

Now that `DQ_Rules` is in the semantic model, reference it to determine which checks to add to FactLoan. 

**Workflow:**
1. For each row in `DQ_Rules` where `TableName = "FactLoan"`
2. Use `RuleType` to select the appropriate M code pattern (from [pq-check-patterns.md](../references/pq-check-patterns.md))
3. Create a Power Query step named after `RuleName` (e.g., `Step_LoanID_IsBlank`)
4. Use rule parameters (`AllowedValues`, `MinValue`, `MaxValue`, etc.) to configure the check

**Reference to DQ_Rules in Power Query:**
While Power Query cannot directly reference the DAX table `DQ_Rules` during query load, you document the mapping:

| DQ_Rules Row | RuleType | M Pattern | Ref |
|---|---|---|---|
| LoanID_IsBlank | Blank | Blank detection | [Pattern 1](../references/pq-check-patterns.md#pattern-1--blank-detection) |
| LoanID_IsDuplicate | Duplicate | Duplicate detection | [Pattern 2](../references/pq-check-patterns.md#pattern-2--duplicate-detection) |
| Amount_IsValidNumber | Type | Numeric validation | [Pattern 3](../references/pq-check-patterns.md#pattern-3--type-validation-numeric) |
| Amount_IsInRange | Range | Range check (10000-5000000) | [Pattern 6](../references/pq-check-patterns.md#pattern-6--range-check) |
| Date_IsValidDate | Type | Date validation | [Pattern 4](../references/pq-check-patterns.md#pattern-4--type-validation-date) |
| Status_IsAllowed | Domain | Domain check (Approved\|Pending\|...) | [Pattern 5](../references/pq-check-patterns.md#pattern-5--domainallowed-value-check) |
| PropertyID_IsMissingInDim | RI | FK missing check → DimProperty | [Pattern 7](../references/pq-check-patterns.md#pattern-7--referential-integrity-fk-missing) |
| ProductID_IsMissingInDim | RI | FK missing check → DimProduct | [Pattern 7](../references/pq-check-patterns.md#pattern-7--referential-integrity-fk-missing) |

### Source Options

Choose one based on your setup:

**Option A: Reference existing query**
```m
Source = FactLoan_RawData  // Reference another Power Query table already in the model
```

**Option B: Direct SQL connection** (preferred for large data)
```m
Source = Sql.Database("your-server", "your-database", [Query = "SELECT * FROM dbo.FactLoan"])
```

**Option C: Dataflow or Other Source**
```m
Source = OtherDataflowOutput
```

### Complete PQ Query (All DQ Steps)

Append these steps to your FactLoan source, implementing each check from `DQ_Rules`:

```m
let
  Source = FactLoan_RawData,  // <- Replace with your source reference
  
  // (Optional: If Source needs headers promoted)
  PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
  Data = PromotedHeaders,  // <- Or just `Data = Source` if headers already exist
  
  // ===== BLANK CHECKS =====
  Step_BlankCheck_LoanID = Table.AddColumn(
    Data,
    "LoanID_IsBlank",
    each if Text.Trim([LoanID]) = "" or [LoanID] = null then 1 else 0,
    type number
  ),
  
  // ===== DUPLICATE DETECTION (Composite Key: LoanID + AssetID) =====
  Step_GroupByKey = Table.Group(
    Step_BlankCheck_LoanID,
    {"LoanID", "AssetID"},
    {{"RowCount", Table.RowCount}}
  ),
  Step_MarkDuplicates = Table.Join(
    Step_BlankCheck_LoanID,
    {"LoanID", "AssetID"},
    Step_GroupByKey,
    {"LoanID", "AssetID"},
    JoinKind.LeftOuter
  ),
  Step_DuplicateFlag = Table.AddColumn(
    Step_MarkDuplicates,
    "LoanID_AssetID_IsDuplicate",
    each if [RowCount] > 1 then 1 else 0,
    type number
  ),
  Step_RemoveRowCount = Table.RemoveColumns(Step_DuplicateFlag, {"RowCount"}),
  
  // ===== TYPE VALIDATION: NUMERIC =====
  Step_ValidateAmount = Table.AddColumn(
    Step_RemoveRowCount,
    "LoanAmount_IsValidNumber",
    each try (
      if Value.Is(Value.FromText([LoanAmount]), type number) then 1 else 0
    ) otherwise 0,
    type number
  ),
  
  // ===== RANGE CHECK =====
  Step_AmountInRange = Table.AddColumn(
    Step_ValidateAmount,
    "LoanAmount_IsInRange",
    each try (
      let amount = Value.FromText([LoanAmount])
      in if amount >= 10000 and amount <= 5000000 then 1 else 0
    ) otherwise 0,
    type number
  ),
  
  // ===== TYPE VALIDATION: DATE =====
  Step_ValidateDate = Table.AddColumn(
    Step_AmountInRange,
    "OriginationDate_IsValidDate",
    each try (
      if Value.Is(Date.FromText([OriginationDate], "en-US"), type date) then 1 else 0
    ) otherwise 0,
    type number
  ),
  
  // ===== DOMAIN CHECK: ApprovalStatus =====
  Step_DomainCheck_Status = Table.AddColumn(
    Step_ValidateDate,
    "ApprovalStatus_IsAllowed",
    each if Text.Lower(Text.Trim([ApprovalStatus])) in 
           {"approved", "pending", "rejected", "withdrawn"} 
           then 1 else 0,
    type number
  ),
  
  // ===== FK CHECK: PropertyID → DimProperty =====
  // Assuming DimProperty is loaded as a query before this one
  // Alternative: You can also join on-the-fly by loading from CSV/database
  Step_JoinProperty = Table.NestedJoin(
    Step_DomainCheck_Status,
    {"PropertyID"},
    DimProperty,
    {"PropertyID"},
    "DIM_Property",
    JoinKind.LeftOuter
  ),
  Step_ExpandProperty = Table.ExpandTableColumn(
    Step_JoinProperty,
    "DIM_Property",
    {"PropertyID"},
    {"DIM_PropertyID"}
  ),
  Step_PropertyFKCheck = Table.AddColumn(
    Step_ExpandProperty,
    "PropertyID_IsMissingInDim",
    each if [DIM_PropertyID] = null then 1 else 0,
    type number
  ),
  Step_RemovePropertyKey = Table.RemoveColumns(Step_PropertyFKCheck, {"DIM_PropertyID"}),
  
  // ===== FK CHECK: ProductID → DimProduct =====
  Step_JoinProduct = Table.NestedJoin(
    Step_RemovePropertyKey,
    {"ProductID"},
    DimProduct,
    {"ProductID"},
    "DIM_Product",
    JoinKind.LeftOuter
  ),
  Step_ExpandProduct = Table.ExpandTableColumn(
    Step_JoinProduct,
    "DIM_Product",
    {"ProductID"},
    {"DIM_ProductID"}
  ),
  Step_ProductFKCheck = Table.AddColumn(
    Step_ExpandProduct,
    "ProductID_IsMissingInDim",
    each if [DIM_ProductID] = null then 1 else 0,
    type number
  ),
  Step_RemoveProductKey = Table.RemoveColumns(Step_ProductFKCheck, {"DIM_ProductID"}),
  
  // ===== COMBINE FLAGS INTO RowHasIssues =====
  Step_RowHasIssues = Table.AddColumn(
    Step_RemoveProductKey,
    "RowHasIssues",
    each [LoanID_IsBlank] = 1 or 
         [LoanID_AssetID_IsDuplicate] = 1 or 
         [LoanAmount_IsValidNumber] = 0 or
         [LoanAmount_IsInRange] = 0 or
         [OriginationDate_IsValidDate] = 0 or
         [ApprovalStatus_IsAllowed] = 0 or
         [PropertyID_IsMissingInDim] = 1 or
         [ProductID_IsMissingInDim] = 1,
    type logical
  )
  
in
  Step_RowHasIssues
```

### Validation: Ensure Column Names Match DQ_Rules

After applying the PQ query, verify that each generated flag column name matches `RuleName` in `DQ_Rules`:

**Check List:**
- ✓ Column `LoanID_IsBlank` exists in FactLoan
- ✓ Column `LoanID_AssetID_IsDuplicate` exists in FactLoan
- ✓ Column `Amount_IsValidNumber` exists in FactLoan
- ✓ Column `Amount_IsInRange` exists in FactLoan
- ✓ Column `Date_IsValidDate` exists in FactLoan
- ✓ Column `Status_IsAllowed` exists in FactLoan
- ✓ Column `PropertyID_IsMissingInDim` exists in FactLoan
- ✓ Column `ProductID_IsMissingInDim` exists in FactLoan
- ✓ Column `RowHasIssues` exists in FactLoan

**Mismatch handling:** If a column name doesn't match `DQ_Rules[RuleName]`, either:
1. Rename the PQ column to match `RuleName` (preferred)
2. Update `DQ_Rules` to match the PQ column name (if the PQ naming is intentional)
3. Later in Step 3, the `DQ_Rules_WithModelType` join will show mismatches as nulls

### How This Fits in PBIP

In a **Power BI Project (PBIP)**, your FactLoan query would be:
1. **Part of the semantic model's data sources**
2. **Defined in Power Query Editor** (Queries pane)
3. **References sourced from:**
   - SQL database connections (Environment variables in PBIP)
   - Imported queries (other `.pqx` files)
   - Dataflow outputs (if staging in a dataflow)
4. **All steps are version-controlled** (steps visible in `definition/` PBIP folder)

Multiple queries can share the same `Source`:
```
RawFactLoan (loads from SQL)
  ↓
FactLoan (adds DQ flags) — uses RawFactLoan as source
FactLoan_Archive (historical data) — also uses RawFactLoan
DQ_Profiling (audit table) — references FactLoan, groups/counts
```

> **Advantage:** Changes to source connection are made once; all dependent queries auto-update.

### Result Columns Added to FactLoan

Based on the `DQ_Rules` registry, these columns are now in FactLoan:
- `LoanID_IsBlank` (1 = blank, 0 = OK)
- `LoanID_AssetID_IsDuplicate` (1 = duplicate, 0 = unique)
- `Amount_IsValidNumber` (1 = valid, 0 = parse error)
- `Amount_IsInRange` (1 = within range, 0 = outside range)
- `OriginationDate_IsValidDate` (1 = valid, 0 = parse error)
- `ApprovalStatus_IsAllowed` (1 = in allowed list, 0 = invalid)
- `PropertyID_IsMissingInDim` (1 = missing, 0 = found)
- `ProductID_IsMissingInDim` (1 = missing, 0 = found)
- `RowHasIssues` (true = at least one issue, false = OK)

---

## Step 3 — DAX Model Setup

### 3a) Create Model Inventory (Calculated Table)

In the Semantic Model, add a calculated table for reference (optional but useful):

```dax
Model_Columns =
SELECTCOLUMNS(
    INFO.COLUMNS(),
    "TableName", [Table],
    "ColumnName", [Name],
    "DataType", [DataType],
    "IsHidden", [IsHidden]
)
```

### 3b) Create Rules Coverage Table — Cross-Reference DQ_Rules to Implementation

The `DQ_Rules_WithModelType` table joins your rules registry with the actual model columns, showing which rules have been implemented and which are missing:

```dax
DQ_Rules_WithModelType =
NATURALLEFTOUTERJOIN(
    DQ_Rules,
    Model_Columns
)
```

**Result:** For each row in `DQ_Rules`:
- If a matching column exists in the model (matched by `RuleName`), the join includes model metadata (TableName, ColumnName, DataType, IsHidden)
- If no matching column exists, the model columns are blank (null) — indicating the rule has not been implemented

**Example output:**

| TableName | ColumnName | RuleName | ExpectedType | ColumnName_Model | DataType_Model | IsHidden_Model |
|-----------|-----------|----------|----------|----------|----------|----------|
| FactLoan | LoanID | LoanID_IsBlank | string | LoanID_IsBlank | Integer | false |
| FactLoan | LoanID | LoanID_IsDuplicate | string | LoanID_IsDuplicate | Integer | false |
| FactLoan | LoanAmount | Amount_IsInRange | number | Amount_IsInRange | Integer | false |
| **FactLoan** | **LoanYear** | **Year_IsValidNumber** | **number** | **[null]** | **[null]** | **[null]** |

The last row shows a rule (`Year_IsValidNumber`) that exists in `DQ_Rules` but has no corresponding PQ column — it hasn't been implemented yet.

> **Note:** In a PBIP project, save this as a new file `definition/tables/DQ_Rules_WithModelType.tmdl` and add `ref table DQ_Rules_WithModelType` to `model.tmdl`.

---

## Step 4 — DAX Measures

Add these measures to aggregate the pre-computed PQ flags. Each measure references a column created in Step 2 (based on `DQ_Rules` from Step 1).

Add these measures to the **_Measures table** (or dedicated DQ measures table).

### Core Aggregation Measures

**Note:** These measures filter and aggregate the **pre-computed flag columns** from Step 2. No re-calculation happens; they simply count/sum the flags.

```dax
// Count of rows with any DQ issue
measure 'DQ - FactLoan Invalid Rows' = 
    CALCULATE(
        COUNTROWS(FactLoan),
        FactLoan[RowHasIssues] = TRUE()
    )

// Percentage of invalid rows
measure 'DQ - FactLoan Invalid Rows %' =
    DIVIDE(
        [DQ - FactLoan Invalid Rows],
        COUNTROWS(FactLoan)
    )

// Breakdown by rule type (sample measures)
measure 'DQ - FactLoan Blank Key Count' =
    CALCULATE(COUNTROWS(FactLoan), FactLoan[LoanID_IsBlank] = 1)

measure 'DQ - FactLoan Duplicate Count' =
    CALCULATE(COUNTROWS(FactLoan), FactLoan[LoanID_AssetID_IsDuplicate] = 1)

measure 'DQ - FactLoan Invalid Amount Count' =
    CALCULATE(
        COUNTROWS(FactLoan),
        FactLoan[LoanAmount_IsValidNumber] = 0 OR FactLoan[LoanAmount_IsInRange] = 0
    )

measure 'DQ - FactLoan FK Missing Count' =
    CALCULATE(
        COUNTROWS(FactLoan),
        FactLoan[PropertyID_IsMissingInDim] = 1 OR FactLoan[ProductID_IsMissingInDim] = 1
    )

// Rules coverage: what % of rules have corresponding model columns?
measure 'DQ - Rules Coverage %' =
    DIVIDE(
        CALCULATE(
            COUNTROWS(DQ_Rules_WithModelType),
            NOT(ISBLANK(DQ_Rules_WithModelType[ColumnName]))  // Rules that have model columns
        ),
        CALCULATE(
            COUNTROWS(DQ_Rules),
            NOT(ISBLANK(DQ_Rules[ExpectedType]))  // Total rules in registry
        )
    )
    // Example: 6 out of 8 rules implemented = 75% coverage
```

---

## Step 5 — Report Pages

### Page 1: DQ Overview (KPIs)

Add card visuals showing:
- `DQ - FactLoan Invalid Rows` (card)
- `DQ - FactLoan Invalid Rows %` (gauge, highlight if > 5%)
- `DQ - Rules Coverage %` (KPI card)

Matrix visual showing breakdown by rule type:

| RuleName | Count |
|----------|-------|
| LoanID_IsBlank | 12 |
| LoanID_AssetID_IsDuplicate | 5 |
| Amount_IsValidNumber | 34 |
| Amount_IsInRange | 8 |
| Date_IsValidDate | 2 |
| ... | ... |

### Page 2: Exceptions (Drill-Through)

Create a table visual that shows **all rows where `RowHasIssues = TRUE()`**.

**Columns to display:**
- LoanID, AssetID (context)
- LoanAmount, OriginationDate, ApprovalStatus (key fields)
- **DQ flags:** LoanID_IsBlank, LoanID_AssetID_IsDuplicate, LoanAmount_IsValidNumber, LoanAmount_IsInRange, OriginationDate_IsValidDate, ApprovalStatus_IsAllowed, PropertyID_IsMissingInDim, ProductID_IsMissingInDim

**Filter:** FactLoan[RowHasIssues] = TRUE()

**User interaction:** Scan the flag columns left-to-right; any flag = 1 or 0 (depending on rule) indicates which validation failed. Then:
- 1 = issue found (for IsBlank, IsDuplicate, IsMissingInDim)
- 0 = issue found (for IsValidNumber, IsValidDate, IsAllowed, IsInRange)

### Page 3: Coverage (Rules Audit)

Table visual showing `DQ_Rules_WithModelType` with columns:

| TableName | ColumnName | RuleType | RuleName | DataType | (Model exists?) |
|-----------|-----------|----------|----------|----------|-----------------|
| FactLoan | LoanID | Blank | LoanID_IsBlank | string | ✓ |
| FactLoan | LoanID | Duplicate | LoanID_IsDuplicate | string | ✓ |
| FactLoan | LoanAmount | Type | Amount_IsValidNumber | number | ✓ |
| FactLoan | LoanAmount | Range | Amount_IsInRange | number | ✓ |
| **FactLoan** | **LoanYear** | **Type** | **Year_IsValidNumber** | **number** | **✗ (missing)** |

Highlight rows where ColumnName is null (rules without model support).

---

## Step 6 — Performance Validation

### Before/After Comparison

**Metric:** Memory footprint for FactLoan with 100k rows

| Approach | Column Count | Memory (Approx.) | Query Latency (Row)→Filters |
|----------|-------------|------------------|---------------------------|
| DAX calculated columns (old) | 6 flags | ~8–12 MB | 200–500 ms (recalc per filter) |
| PQ flags (new) | 6 flags | ~2–4 MB | <50 ms (pre-computed) |
| Savings | — | ~60–70% | ~80–90% |

**Why the savings?**
1. PQ flags are **single-pass evaluation** at load; no re-calculation per filter
2. Boolean columns in PQ are **compressed** efficiently (~1 bit per row in memory)
3. DAX `IssueList` UNION patterns are eliminated (removed per refactor thesis)
4. Filters on pre-computed columns are O(1) lookups, not O(n) DAX expressions

### Test Locally

1. **In Power Query Editor:**
   - Open FactLoan query
   - Verify all DQ steps apply without errors (Applied Steps pane shows all steps)
   - Preview to confirm new flag columns are populated
   
2. **Refresh the semantic model:**
   - In Power BI Desktop: Ctrl+Shift+R (refresh all)
   - Wait for model to re-calculate
   
3. **Verify FactLoan now has the 8 new flag columns** (plus all source columns)

4. **Check Memory Performance Analyzer:**
   - View → Performance Analyzer
   - Refresh or interact with slicers/cards
   - Compare latency before/after adding DQ steps
   - Expected: <50ms for filter operations (vs. 200–500ms with DAX calculated columns)

---

## Step 7: Iteration & Maintenance

**All changes start with `DQ_Rules`.** This is your single source of truth for data quality governance.

### Adding a New Rule

Example: You want to flag loans with unusual interest rates.

1. **Add to the `DQ_Rules` query inline JSON** (open Advanced Editor, append to the `dq_rules` array):
   ```m
   // Add this object inside the ""dq_rules"" array in RawJson:
   {
     ""id"": 9, ""table_name"": ""FactLoan"", ""column_name"": ""InterestRate"",
     ""rule_type"": ""Range"", ""rule_name"": ""InterestRate_IsInRange"",
     ""rule_definition"": ""Between 2% and 15%"",
     ""expected_type"": ""number"", ""allowed_values"": null,
     ""min_value"": 0.02, ""max_value"": 0.15
   }
   ```

2. **Add PQ column:**
   ```m
   Step_InterestRateCheck = Table.AddColumn(
     Source,
     "InterestRate_IsInRange",
     each try (
       let rate = Value.FromText([InterestRate])
       in if rate >= 0.02 and rate <= 0.15 then 1 else 0
     ) otherwise 0,
     type number
   )
   ```

3. **Update `RowHasIssues`:**
   ```m
   Step_RowHasIssues = Table.AddColumn(
     Source,
     "RowHasIssues",
     each [LoanID_IsBlank] = 1 or ... or [InterestRate_IsInRange] = 0,
     type logical
   )
   ```

4. **Refresh Power BI:** PQ applies changes; DAX measures automatically reference the new flag.

### Removing a Rule

1. Delete the rule object from the `RawJson` string in the `DQ_Rules` Advanced Editor
2. Remove the corresponding `Step_*` in the FactLoan PQ query
3. Remove the flag from `RowHasIssues` logic
4. Close & Apply → refresh model
5. Commit PBIP changes to git

---

## Addressing Common Questions

### Q: How do I export exceptions for downstream systems?

**A:** Use Power BI Dataflow export or Power Query sink to CSV/database:
```m
// At end of FactLoan query
Sink = csv.Folder(..., [FileCompressionType.None])
```
Or export from a report visual to Excel.

### Q: Can I version control the DQ rules?

**A:** Yes. Since the rules are embedded in the `DQ_Rules` Power Query query, they are version-controlled as part of the PBIP project's query definitions. In a PBIP project, Power Query queries are stored in the `definition/` folder — any change to the inline JSON string is tracked by git.

**Workflow:**
1. Open the `DQ_Rules` query in Advanced Editor
2. Edit the inline JSON string (add/remove/update rule objects)
3. Close & Apply → refresh model
4. Commit the PBIP definition files to git

**Finding the query in PBIP files:**
The `DQ_Rules` query M code will be visible in the PBIP semantic model definition files, making the entire rules registry diff-friendly in pull requests.

### Q: What if a dimension table is very large? Will FK check slow down my PQ?

**A:** Possible. Two mitigations:
1. Use indexed joins (native Power Query performance)
2. Move FK checks to DAX using `RELATED()` functions:
   ```dax
   column PropertyID_IsMissingInDim =
       IF(ISBLANK(RELATED(DimProperty[PropertyID])), 1, 0)
   ```
   Then import DimProperty and create relationships in the model.

### Q: Can I schedule PQ to run validation without loading all data?

**A:** Yes. Create a separate "DQ Profiling" query that skips the FactLoan raw data and instead:
1. Groups FactLoan on key columns
2. Counts distinct values
3. Checks for outliers
4. Exports to a separate table for analysis

---

## Summary

This example demonstrates:
1. **Rules registry** as a JSON-based single source of truth (stored in `definition/` for version control)
2. **Power Query import** of JSON to create `DQ_Rules` table in the semantic model
3. **Power Query** for efficient per-row flag computation (all visible in Applied Steps)
4. **DAX measures** for aggregation and KPI reporting (fast because flags are pre-computed)
5. **Report pages** that let users quickly spot bad data (Exceptions page) and track coverage (Coverage page)

**Next step:** Apply this pattern to other fact tables (FactProperty, FactAppraisal, etc.) and layer additional custom rules based on business requirements.

