# Power Query DQ Check Patterns — M Code Snippets

This reference provides **copy-paste M code templates** for common per-row DQ checks in Power Query. Each pattern is self-contained; chain them as steps in Applied Steps UI.

---

## Overview

Each pattern adds a **boolean or numeric column** (0/1 flags) to your source table. Examples assume:
- Source table: already loaded via `Source = ...`
- Key columns: `[LoanID]`, `[AssetID]`, `[PropertyID]`
- Critical fields: `[Amount]`, `[ApprovalDate]`, `[ApprovalStatus]`
- Dimension table: `Dimension_ApprovalStatus` with column `[StatusCode]`

All patterns use `Table.AddColumn()` to preserve audit trail.

---

## Pattern 1 — Blank Detection

Detect when a key or critical field is empty, null, or whitespace.

### M Snippet — Single Column Blank Check
```m
let
  Source = ...,
  BlankCheck = Table.AddColumn(
    Source,
    "LoanID_IsBlank",
    each if Text.Trim([LoanID]) = "" or [LoanID] = null then 1 else 0,
    type number
  )
in
  BlankCheck
```

**Notes:**
- Use `Text.Trim()` to remove leading/trailing spaces before checking
- Return `1` = flag found, `0` = flag not found (easier to aggregate)
- Specify `type number` to avoid type inference issues

### M Variant — Composite Key Blank Check
```m
let
  Source = ...,
  BlankCheck = Table.AddColumn(
    Source,
    "LoanID_AssetID_IsBlank",
    each if (Text.Trim([LoanID]) = "" or [LoanID] = null) or 
           (Text.Trim([AssetID]) = "" or [AssetID] = null) 
           then 1 else 0,
    type number
  )
in
  BlankCheck
```

---

## Pattern 2 — Duplicate Detection

Mark rows where the key (or composite key) appears more than once in the table.

### M Snippet — Single Key Duplicate Detection
```m
let
  Source = ...,
  GroupedByKey = Table.Group(
    Source,
    {"LoanID"},
    {{"RowCount", Table.RowCount}}
  ),
  MarkedDuplicates = Table.Join(
    Source,
    {"LoanID"},
    GroupedByKey,
    {"LoanID"},
    JoinKind.LeftOuter
  ),
  AddDuplicateFlag = Table.AddColumn(
    MarkedDuplicates,
    "LoanID_IsDuplicate",
    each if [RowCount] > 1 then 1 else 0,
    type number
  ),
  DropHelper = Table.RemoveColumns(AddDuplicateFlag, {"RowCount"})
in
  DropHelper
```

**Notes:**
- `Table.Group()` counts occurrences in a single pass (efficient)
- Left-outer join preserves all source rows
- Remember to drop the helper column `RowCount` at the end

### M Variant — Composite Key Duplicate Detection
```m
let
  Source = ...,
  GroupedByKeys = Table.Group(
    Source,
    {"LoanID", "AssetID"},
    {{"RowCount", Table.RowCount}}
  ),
  MarkedDuplicates = Table.Join(
    Source,
    {"LoanID", "AssetID"},
    GroupedByKeys,
    {"LoanID", "AssetID"},
    JoinKind.LeftOuter
  ),
  AddDuplicateFlag = Table.AddColumn(
    MarkedDuplicates,
    "LoanID_AssetID_IsDuplicate",
    each if [RowCount] > 1 then 1 else 0,
    type number
  ),
  DropHelper = Table.RemoveColumns(AddDuplicateFlag, {"RowCount"})
in
  DropHelper
```

---

## Pattern 3 — Type Validation (Numeric)

Detect rows where a field cannot be converted to a number.

### M Snippet — Numeric Type Check
```m
let
  Source = ...,
  NumericCheck = Table.AddColumn(
    Source,
    "Amount_IsValidNumber",
    each try (
      let result = Value.FromText([Amount]) in
        if Value.Is(result, type number) then 1 else 0
    ) otherwise 0,
    type number
  )
in
  NumericCheck
```

**Notes:**
- `Value.FromText()` converts to appropriate type; `Value.Is()` confirms it's numeric
- `otherwise 0` marks conversion failures as invalid (flag = 0)
- Alternative shorter form:

```m
each try (if Value.Is(Value.FromText([Amount]), type number) then 1 else 0) otherwise 0
```

---

## Pattern 4 — Type Validation (Date)

Detect rows where a date field cannot be parsed, respecting regional formats.

### M Snippet — Date Type Check (US Format)
```m
let
  Source = ...,
  DateCheck = Table.AddColumn(
    Source,
    "ApprovalDate_IsValidDate",
    each try (
      let result = Date.FromText([ApprovalDate], "en-US") in
        if Value.Is(result, type date) then 1 else 0
    ) otherwise 0,
    type number
  )
in
  DateCheck
```

### M Variant — Date Check with Culture Parameter
```m
let
  Source = ...,
  CultureFormat = "en-GB",  // Change per row region if available
  DateCheck = Table.AddColumn(
    Source,
    "ApprovalDate_IsValidDate",
    each try (
      let result = Date.FromText([ApprovalDate], CultureFormat) in
        if Value.Is(result, type date) then 1 else 0
    ) otherwise 0,
    type number
  )
in
  DateCheck
```

**Notes:**
- Culture codes: "en-US" (MM/DD/YYYY), "en-GB" (DD/MM/YYYY), "de-DE" (DD.MM.YYYY), etc.
- If date format varies by row, use `if [Country] = "US" then "en-US" else "en-GB"` inside the expression

---

## Pattern 5 — Domain/Allowed Value Check

Detect rows where a field value is not in an allowed list.

### M Snippet — Domain Check (Static List)
```m
let
  Source = ...,
  AllowedStatuses = {"Approved", "Pending", "Rejected"},
  DomainCheck = Table.AddColumn(
    Source,
    "ApprovalStatus_IsAllowed",
    each if Text.Trim([ApprovalStatus]) in AllowedStatuses then 1 else 0,
    type number
  )
in
  DomainCheck
```

**Notes:**
- Use `Text.Trim()` to handle whitespace
- List is case-sensitive; normalize with `Text.Lower()` if needed:

```m
each if Text.Lower(Text.Trim([ApprovalStatus])) in {"approved", "pending", "rejected"} then 1 else 0
```

### M Variant — Domain Check (From Another Table)
```m
let
  Source = ...,
  AllowedValues = Dimension_ApprovalStatus,
  DomainCheck = Table.AddColumn(
    Source,
    "ApprovalStatus_IsAllowed",
    each if List.Contains(
      AllowedValues[StatusCode],
      [ApprovalStatus]
    ) then 1 else 0,
    type number
  )
in
  DomainCheck
```

---

## Pattern 6 — Range Check

Detect rows where a numeric field is outside an expected range.

### M Snippet — Range Check
```m
let
  Source = ...,
  RangeCheck = Table.AddColumn(
    Source,
    "Amount_IsInRange",
    each try (
      let value = Value.FromText([Amount])
      in if value >= 0 and value <= 1000000 then 1 else 0
    ) otherwise 0,
    type number
  )
in
  RangeCheck
```

**Notes:**
- First validate type (using `try...otherwise`), then check bounds
- Customize range per field: `>= MinValue and <= MaxValue`

### M Variant — Range Check with Inclusive/Exclusive Bounds
```m
each try (
  let value = Value.FromText([Amount])
  in if value > 0 and value < 1000000 then 1 else 0  // Exclusive
) otherwise 0
```

---

## Pattern 7 — Referential Integrity (FK Missing)

Detect rows where a foreign key value is missing in the referenced dimension.

### M Snippet — FK Missing Check (Left-Outer Join)
```m
let
  Source = ...,
  Dimension = Dimension_ApprovalStatus,
  FKJoin = Table.NestedJoin(
    Source,
    {"ApprovalStatusCode"},
    Dimension,
    {"StatusCode"},
    "DIM",
    JoinKind.LeftOuter
  ),
  ExpandDim = Table.ExpandTableColumn(
    FKJoin,
    "DIM",
    {"StatusCode"},
    {"DIM_StatusCode"}
  ),
  AddFKCheck = Table.AddColumn(
    ExpandDim,
    "ApprovalStatus_IsMissingInDim",
    each if [DIM_StatusCode] = null then 1 else 0,
    type number
  ),
  CleanUp = Table.RemoveColumns(AddFKCheck, {"DIM_StatusCode"})
in
  CleanUp
```

**Notes:**
- Use `NestedJoin()` with `KindKind.LeftOuter` to keep all source rows
- Null on dimension side = FK is missing
- Remove the dimension key after check to avoid redundancy

### M Variant — FK Check (Multiple Keys)
```m
let
  Source = ...,
  Dimension = Dimension_LoanProduct,
  FKJoin = Table.NestedJoin(
    Source,
    {"ProductType", "ProductYear"},
    Dimension,
    {"Type", "Year"},
    "DIM",
    JoinKind.LeftOuter
  ),
  ExpandDim = Table.ExpandTableColumn(
    FKJoin,
    "DIM",
    {"Type"},  // Just need one non-null column to check existence
    {"DIM_Type"}
  ),
  AddFKCheck = Table.AddColumn(
    ExpandDim,
    "Product_IsMissingInDim",
    each if [DIM_Type] = null then 1 else 0,
    type number
  ),
  CleanUp = Table.RemoveColumns(AddFKCheck, {"DIM_Type"})
in
  CleanUp
```

---

## Pattern 8 — Combine Flags into `RowHasIssues`

After adding all individual flag columns, create a summary column that marks any row with at least one issue.

### M Snippet — Composite Issue Flag
```m
let
  Source = ...,
  // ... (all individual flag columns already added) ...
  RowHasIssues = Table.AddColumn(
    Source,
    "RowHasIssues",
    each [LoanID_IsBlank] = 1 or 
         [LoanID_IsDuplicate] = 1 or 
         [Amount_IsValidNumber] = 0 or
         [ApprovalDate_IsValidDate] = 0 or
         [ApprovalStatus_IsAllowed] = 0 or
         [Amount_IsInRange] = 0 or
         [ApprovalStatus_IsMissingInDim] = 1,
    type logical
  )
in
  RowHasIssues
```

**Notes:**
- Use `or` to combine flags with `= 1` (or `= 0` for invalid checks)
- Return `type logical` (true/false) for cleaner aggregation in DAX
- Alternative: return `type number` (1/0) if you prefer numeric flags throughout

---

## Pattern 9 — Multi-Step Example: FactLoan

Complete example combining blank check, duplicate detection, and type validation on a FactLoan table.

### Complete PQ Query
```m
let
  Source = Csv.Document(
    File.Contents("C:\Data\FactLoan.csv"),
    [Delimiter = ",", Columns = 100, Encoding = 1252, QuoteStyle = QuoteStyle.None]
  ),
  PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
  
  // Step 1: Blank checks
  BlankCheck_LoanID = Table.AddColumn(
    PromotedHeaders,
    "LoanID_IsBlank",
    each if Text.Trim([LoanID]) = "" or [LoanID] = null then 1 else 0,
    type number
  ),
  
  // Step 2: Duplicate detection
  GroupedByLoanID = Table.Group(
    BlankCheck_LoanID,
    {"LoanID"},
    {{"RowCount", Table.RowCount}}
  ),
  JoinDuplicates = Table.Join(
    BlankCheck_LoanID,
    {"LoanID"},
    GroupedByLoanID,
    {"LoanID"},
    JoinKind.LeftOuter
  ),
  DuplicateFlag = Table.AddColumn(
    JoinDuplicates,
    "LoanID_IsDuplicate",
    each if [RowCount] > 1 then 1 else 0,
    type number
  ),
  DropRowCount = Table.RemoveColumns(DuplicateFlag, {"RowCount"}),
  
  // Step 3: Type validation
  NumericCheck = Table.AddColumn(
    DropRowCount,
    "Amount_IsValidNumber",
    each try (if Value.Is(Value.FromText([Amount]), type number) then 1 else 0) otherwise 0,
    type number
  ),
  
  DateCheck = Table.AddColumn(
    NumericCheck,
    "ApprovalDate_IsValidDate",
    each try (if Value.Is(Date.FromText([ApprovalDate], "en-US"), type date) then 1 else 0) otherwise 0,
    type number
  ),
  
  // Step 4: Combine flags
  RowHasIssues = Table.AddColumn(
    DateCheck,
    "RowHasIssues",
    each [LoanID_IsBlank] = 1 or [LoanID_IsDuplicate] = 1 or [Amount_IsValidNumber] = 0 or [ApprovalDate_IsValidDate] = 0,
    type logical
  )
in
  RowHasIssues
```

**Result:** FactLoan now has columns: `LoanID_IsBlank`, `LoanID_IsDuplicate`, `Amount_IsValidNumber`, `ApprovalDate_IsValidDate`, `RowHasIssues`.

---

## Tips & Tricks

### Using Variables for Reusable Lists
```m
let
  Source = ...,
  AllowedStatuses = {"Approved", "Pending", "Rejected"},
  AllowedRegions = {"US", "CA", "MX"},
  DomainCheck1 = Table.AddColumn(Source, "Status_IsAllowed", 
    each if [Status] in AllowedStatuses then 1 else 0),
  DomainCheck2 = Table.AddColumn(DomainCheck1, "Region_IsAllowed",
    each if [Region] in AllowedRegions then 1 else 0)
in
  DomainCheck2
```

### Referencing Dynamic Lists from Other Queries
```m
let
  Source = ...,
  AllowedValues = AllowedValuesQuery,  // Reference another query
  DomainCheck = Table.AddColumn(
    Source,
    "Status_IsAllowed",
    each if [Status] in AllowedValues[StatusCode] then 1 else 0
  )
in
  DomainCheck
```

### Testing Flag Logic (Quick Preview)
```m
let
  Source = ...,
  // ... add flags ...
  Preview = Table.SelectRows(RowHasIssues, each [RowHasIssues] = true)
in
  Preview  // Load only bad rows to verify logic
```

---

## Common M Functions Reference

| Function | Purpose | Example |
|----------|---------|---------|
| `Text.Trim()` | Remove leading/trailing spaces | `Text.Trim([Col])` |
| `Text.Length()` | Count characters | `Text.Length([Col]) = 0` |
| `Text.Lower()` / `Text.Upper()` | Case normalization | `Text.Lower([Col])` |
| `Value.FromText()` | Type conversion | `Value.FromText([Amount])` |
| `Value.Is()` | Type check | `Value.Is(Value.FromText([Col]), type number)` |
| `Date.FromText()` | Parse date | `Date.FromText([Col], "en-US")` |
| `List.Contains()` | Check membership | `List.Contains({1,2,3}, [Col])` |
| `Table.Group()` | Count/aggregate by key | `Table.Group(Source, {"Key"}, {{"Count", Table.RowCount}})` |
| `Table.NestedJoin()` | Left-outer join | `Table.NestedJoin(..., JoinKind.LeftOuter)` |
| `Table.AddColumn()` | Add new column | `Table.AddColumn(Source, "NewCol", each expr)` |
| `Table.RemoveColumns()` | Drop columns | `Table.RemoveColumns(Table, {"Col1", "Col2"})` |

