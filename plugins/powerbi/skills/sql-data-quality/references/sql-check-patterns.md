# T-SQL Data Quality Check Patterns

This reference provides **copy-paste T-SQL CASE patterns** for common per-row DQ checks. Each pattern is used in the `WITH Flags AS (...)` CTE of the audit VIEW. All patterns use `1 = problem` polarity.

---

## Overview

Each pattern adds a **DQ flag column** (`1` = problem, `0` = OK) to the CTE SELECT. Examples assume:
- Source table: `[dbo].[Table]` aliased as `src`
- Key columns: `[LoanID]`, `[AssetID]`
- Critical fields: `[CommitmentBalance]`, `[GLDate]`, `[Stage]` 
- Dimension table: `[dbo].[DimOriginator]` with column `[OriginatorID]`

---


## Pattern 1 — Blank Detection

Detect when a key or critical field is null or whitespace.

**AllowBlank note:**
If AllowBlank=1, use THEN 0 for NULL (nulls pass). If AllowBlank=0, use THEN 1 for NULL (nulls fail).

### T-SQL Snippet — Single Column Blank Check

```sql
CASE 
    WHEN src.[LoanID] IS NULL OR LTRIM(RTRIM(CAST(src.[LoanID] AS NVARCHAR(MAX)))) = ''
    THEN 1 
    ELSE 0 
END AS [LoanID_IsBlank]
```

**Notes:**
- Use `LTRIM(RTRIM(...))` to remove leading/trailing spaces before checking
- Cast to `NVARCHAR(MAX)` for safety (handles numeric columns cast to text)
- Return `1` = blank found, `0` = OK
- Works for TEXT, VARCHAR, NVARCHAR, INT, etc.

### T-SQL Variant — Composite Key Blank Check

```sql
CASE 
    WHEN (src.[LoanID] IS NULL OR LTRIM(RTRIM(CAST(src.[LoanID] AS NVARCHAR(MAX)))) = '')
         OR (src.[AssetID] IS NULL OR LTRIM(RTRIM(CAST(src.[AssetID] AS NVARCHAR(MAX)))) = '')
    THEN 1 
    ELSE 0 
END AS [LoanID_AssetID_IsBlank]
```

---

## Pattern 2 — Duplicate Detection

Mark rows where the key (or composite key) appears more than once in the table. Uses window function `COUNT(*) OVER (PARTITION BY ...)` in the CTE.

### T-SQL Snippet — Single Key Duplicate Detection

```sql
WITH Flags AS (
    SELECT 
        src.*,
        CASE 
            WHEN COUNT(*) OVER (PARTITION BY src.[LoanID]) > 1 
            THEN 1 
            ELSE 0 
        END AS [LoanID_IsDuplicate]
    FROM [dbo].[FactLoan] AS src
)
SELECT * FROM Flags
```

**Notes:**
- Window function `COUNT(*) OVER (PARTITION BY ...)` counts occurrences per key
- Must be in CTE; cannot reference window function in WHERE clause of same query level
- Returns `1` if count > 1 (duplicate detected), `0` if count = 1 (unique)

### T-SQL Variant — Composite Key Duplicate Detection

```sql
CASE 
    WHEN COUNT(*) OVER (PARTITION BY src.[LoanID], src.[AssetID]) > 1 
    THEN 1 
    ELSE 0 
END AS [LoanID_AssetID_IsDuplicate]
```

---


## Pattern 3 — Type Validation (Numeric)

Detect rows where a field cannot be converted to a number.

**AllowBlank note:**
If AllowBlank=1, use THEN 0 for NULL (nulls pass). If AllowBlank=0, use THEN 1 for NULL (nulls fail).

### T-SQL Snippet — Numeric Type Check

```sql
CASE 
    WHEN TRY_CAST(src.[CommitmentBalance] AS FLOAT) IS NOT NULL OR src.[CommitmentBalance] IS NULL
    THEN 0  -- valid number OR null (acceptable)
    ELSE 1  -- invalid number (cannot cast)
END AS [CommitmentBalance_IsInvalidNumber]
```

**Notes:**
- `TRY_CAST(col AS FLOAT)` returns NULL if conversion fails, does not error
- Logic: "return 1 (invalid) if TRY_CAST is NULL AND source is NOT NULL"
- Invert: return `0` if valid OR null, `1` if invalid
- Alternative form (more readable):

```sql
CASE 
    WHEN src.[CommitmentBalance] IS NULL THEN 0  -- null is OK
    WHEN TRY_CAST(src.[CommitmentBalance] AS FLOAT) IS NOT NULL THEN 0  -- valid
    ELSE 1  -- invalid
END AS [CommitmentBalance_IsInvalidNumber]
```

**Fallback for SQL Server 2012–2014** (no TRY_CAST):

```sql
CASE 
    WHEN src.[CommitmentBalance] IS NULL THEN 0
    WHEN ISNUMERIC(src.[CommitmentBalance]) = 1 THEN 0  -- ISNUMERIC is loose; accepts '$', scientific
    ELSE 1
END AS [CommitmentBalance_IsInvalidNumber]
```

---


## Pattern 4 — Type Validation (Date)

Detect rows where a date field cannot be parsed.

**AllowBlank note:**
If AllowBlank=1, use THEN 0 for NULL (nulls pass). If AllowBlank=0, use THEN 1 for NULL (nulls fail).

### T-SQL Snippet — Date Type Check

```sql
CASE 
    WHEN src.[GLDate] IS NULL THEN 0  -- null is OK
    WHEN TRY_CAST(src.[GLDate] AS DATE) IS NOT NULL THEN 0  -- valid date
    ELSE 1  -- invalid date
END AS [GLDate_IsInvalidDate]
```

**Notes:**
- `TRY_CAST(col AS DATE)` works for ISO format (YYYY-MM-DD) and CONVERT interpretations
- If date is already DATE type, TRY_CAST passes trivially (no error)
- Allow NULL in AllowBlank=1 rows; fail if AllowBlank=0

### T-SQL Variant — Date Check with Culture Parameter
For text dates in non-ISO format, use `CONVERT()` with style parameter:

```sql
CASE 
    WHEN src.[GLDate] IS NULL THEN 0  -- null is OK
    WHEN TRY_CONVERT(DATE, src.[GLDate], 101) IS NOT NULL THEN 0  -- US format MM/DD/YYYY (style 101)
    ELSE 1  -- invalid
END AS [GLDate_IsInvalidDate]
```

**Common style values:**
- `101` = US MM/DD/YYYY
- `103` = UK DD/MM/YYYY
- `120` = ISO YYYY-MM-DD (default for most systems)

---


## Pattern 5 — Domain Validation (Allowed Values)

Detect rows where a field value is not in the approved list.

**Note:** AllowedValues is mandatory for Domain rules; script will throw if missing.

### T-SQL Snippet — Domain Check with IN Clause

```sql
CASE 
    WHEN src.[Stage] IS NULL THEN 0  -- null is OK
    WHEN src.[Stage] IN (N'Prospecting', N'Approved', N'Closed Won') THEN 0  -- in domain
    ELSE 1  -- not in domain
END AS [Stage_IsOutOfDomain]
```

**Notes:**
- Use `N'value'` prefix for Unicode safety (NVARCHAR)
- Separate values with commas (not pipes; pipes are for CSV format)
- If NULL should fail domain check: `WHEN src.[Stage] IN (...) THEN 0 ELSE 1 END` (no special null handling)
- If NULL should pass: `WHEN src.[Stage] IS NULL OR src.[Stage] IN (...) THEN 0 ELSE 1 END`

### T-SQL Variant — Domain Check with Large List
For many allowed values, consider a helper table:

```sql
-- In CTE, join to domain reference:
CASE 
    WHEN src.[Stage] IS NULL THEN 0
    WHEN EXISTS (SELECT 1 FROM [dbo].[DimStage] WHERE [StageName] = src.[Stage]) THEN 0
    ELSE 1
END AS [Stage_IsOutOfDomain]
```

---

## Pattern 6 — Range Validation

Detect rows where a numeric field is outside expected bounds.

### T-SQL Snippet — Range Check

```sql
CASE 
    WHEN src.[CommitmentBalance] IS NULL THEN 0  -- null is OK
    WHEN TRY_CAST(src.[CommitmentBalance] AS FLOAT) BETWEEN 100 AND 9999999 THEN 0  -- in range
    ELSE 1  -- out of range
END AS [CommitmentBalance_IsOutOfRange]
```

**Notes:**
- Use `TRY_CAST` first to validate type; then check range
- `BETWEEN` is inclusive: [100, 9999999]
- If out-of-range check fails but field is non-numeric, this returns 1 (combines both errors: invalid type AND out of range)

### T-SQL Variant — Exclusive Bounds

```sql
CASE 
    WHEN src.[Probability] IS NULL THEN 0
    WHEN TRY_CAST(src.[Probability] AS FLOAT) > 0 AND TRY_CAST(src.[Probability] AS FLOAT) < 100 THEN 0  -- > 0 AND < 100
    ELSE 1
END AS [Probability_IsOutOfRange]
```

---


## Pattern 7 — Referential Integrity (FK Check)

Detect rows where a foreign key is not found in the reference dimension.

**AllowBlank note:**
If AllowBlank=1, use THEN 0 for NULL (nulls pass). If AllowBlank=0, use THEN 1 for NULL (nulls fail).

### T-SQL Snippet — RI Check with NOT EXISTS

```sql
CASE 
    WHEN src.[OriginatorID] IS NULL THEN 0  -- null FK is OK (AllowBlank=1)
    WHEN NOT EXISTS (SELECT 1 FROM [dbo].[DimOriginator] WHERE [OriginatorID] = src.[OriginatorID]) 
    THEN 1  -- FK not found
    ELSE 0  -- FK found
END AS [OriginatorID_IsMissingInDim]
```

**Notes:**
- Use `NOT EXISTS` (correlated subquery), NOT LEFT JOIN (which can multiply rows in CTE)
- `NOT EXISTS` is faster and avoids row duplication
- Check only if FK is NOT NULL (or adjust per AllowBlank=1/0)
- Reference table must have indexed PK column for good performance

### T-SQL Variant — Composite FK Check

```sql
CASE 
    WHEN src.[OriginatorID] IS NULL OR src.[Year] IS NULL THEN 0
    WHEN NOT EXISTS (
        SELECT 1 FROM [dbo].[DimOriginator] 
        WHERE [OriginatorID] = src.[OriginatorID] AND [Year] = src.[Year]
    )
    THEN 1
    ELSE 0
END AS [OriginatorID_Year_IsMissingInDim]
```

---

## Pattern 8 — Conditional Rules

Apply a rule only if a condition is met (e.g., validate Amount only when Stage='Closed Won').

### T-SQL Snippet — Conditional Range Check

```sql
CASE 
    WHEN src.[Stage] = N'Closed Won'
    THEN (
        CASE 
            WHEN TRY_CAST(src.[CommitmentBalance] AS FLOAT) BETWEEN 100 AND 9999999 THEN 0
            ELSE 1
        END
    )
    ELSE 0  -- rule not applicable; pass
END AS [CommitmentBalance_IsOutOfRange_WhenClosed]
```

**Notes:**
- Outer CASE checks condition (`src.[Stage] = 'Closed Won'`)
- Inner CASE computes the flag
- If condition is false, return `0` (pass; rule doesn't apply)
- Used in ConditionSQL column of CSV to parametrize the condition

---

## Pattern 9 — RowHasIssues Combiner

Combines all flag columns into a single `RowHasIssues` binary indicator.

### T-SQL Snippet — RowHasIssues (Simple OR)

```sql
SELECT
    *,
    CASE 
        WHEN [LoanID_IsBlank] = 1 
          OR [LoanID_IsDuplicate] = 1 
          OR [CommitmentBalance_IsInvalidNumber] = 1 
          OR [CommitmentBalance_IsOutOfRange] = 1 
          OR [GLDate_IsInvalidDate] = 1 
          OR [Stage_IsOutOfDomain] = 1 
          OR [OriginatorID_IsMissingInDim] = 1
        THEN 1 
        ELSE 0 
    END AS RowHasIssues
FROM Flags
```

**Notes:**
- Simple OR-chain of all flag columns = 1
- Standardized polarity makes this logic bulletproof (no inversion)
- Generate this programmatically from CSV RuleType list

---

## Pattern 10 — MaxSeverity Computation

Compute the worst severity of triggered rules for this row.

### T-SQL Snippet — MaxSeverity with Severity Column Join

Normally, severity is passed through the CSV and applied via CASE:

```sql
SELECT
    *,
    CASE 
        WHEN [LoanID_IsBlank] = 1 THEN N'Error'           -- KeyNotBlank severity
        WHEN [LoanID_IsDuplicate] = 1 THEN N'Error'       -- KeyUnique severity
        WHEN [CommitmentBalance_IsInvalidNumber] = 1 THEN N'Warn'   -- TypeNumber
        WHEN [CommitmentBalance_IsOutOfRange] = 1 THEN N'Warn'     -- Range
        WHEN [GLDate_IsInvalidDate] = 1 THEN N'Warn'      -- TypeDate
        WHEN [Stage_IsOutOfDomain] = 1 THEN N'Warn'       -- Domain
        WHEN [OriginatorID_IsMissingInDim] = 1 THEN N'Error'       -- RI
        ELSE NULL  -- no issues
    END AS MaxSeverity
FROM Flags
```

**Notes:**
- Error is "worse" than Warn; use CASE to pick max (Error first in if-chain)
- NULL if no flags triggered
- Generate this from CSV: for each rule, map RuleType + Severity to flag column

---

## Pattern 11 — IssueList Concatenation

Concatenate triggered flag names into a readable semicolon-delimited string using STUFF + CASE.

### T-SQL Snippet — IssueList with STUFF + CASE

```sql
SELECT
    *,
    NULLIF(STUFF(
        CASE WHEN [LoanID_IsBlank] = 1 THEN '; LoanID_IsBlank' ELSE '' END +
        CASE WHEN [LoanID_IsDuplicate] = 1 THEN '; LoanID_IsDuplicate' ELSE '' END +
        CASE WHEN [CommitmentBalance_IsInvalidNumber] = 1 THEN '; CommitmentBalance_IsInvalidNumber' ELSE '' END +
        CASE WHEN [CommitmentBalance_IsOutOfRange] = 1 THEN '; CommitmentBalance_IsOutOfRange' ELSE '' END +
        CASE WHEN [GLDate_IsInvalidDate] = 1 THEN '; GLDate_IsInvalidDate' ELSE '' END +
        CASE WHEN [Stage_IsOutOfDomain] = 1 THEN '; Stage_IsOutOfDomain' ELSE '' END +
        CASE WHEN [OriginatorID_IsMissingInDim] = 1 THEN '; OriginatorID_IsMissingInDim' ELSE '' END,
        1, 2, ''),  -- STUFF(string, start=1, length=2, replacement='')
    '') AS IssueList  -- NULLIF(..., '') converts empty string to NULL
FROM Flags
```

**Result examples:**
- Row with all issues: `"LoanID_IsBlank; CommitmentBalance_IsOutOfRange; GLDate_IsInvalidDate"`
- Row with one issue: `"Stage_IsOutOfDomain"`
- Row with no issues: `NULL`

**Notes:**
- Each CASE appends `'; FlagName'` if flag=1, else empty string `''`
- Concatenate all CASE expressions with `+`
- `STUFF(string, 1, 2, '')` removes the leading `'; '` (positions 1–2)
- `NULLIF(..., '')` converts empty string to NULL (no issues)
- Generate this programmatically from CSV: for each rule, emit one CASE line

---

## Pattern 12 — Complete VIEW Template

Full VIEW DDL combining all patterns above:

```sql
CREATE OR ALTER VIEW [dbo].[FactLoan_DQ_Audit] AS
WITH Flags AS (
    SELECT 
        src.*,
        -- Pattern 1: Blank checks
        CASE WHEN src.[LoanID] IS NULL OR LTRIM(RTRIM(CAST(src.[LoanID] AS NVARCHAR(MAX)))) = '' THEN 1 ELSE 0 END AS [LoanID_IsBlank],
        
        -- Pattern 2: Duplicate checks (window function)
        CASE WHEN COUNT(*) OVER (PARTITION BY src.[LoanID]) > 1 THEN 1 ELSE 0 END AS [LoanID_IsDuplicate],
        
        -- Pattern 3: Type checks
        CASE WHEN src.[CommitmentBalance] IS NULL THEN 0 WHEN TRY_CAST(src.[CommitmentBalance] AS FLOAT) IS NOT NULL THEN 0 ELSE 1 END AS [CommitmentBalance_IsInvalidNumber],
        
        -- Pattern 4: Date type checks
        CASE WHEN src.[GLDate] IS NULL THEN 0 WHEN TRY_CAST(src.[GLDate] AS DATE) IS NOT NULL THEN 0 ELSE 1 END AS [GLDate_IsInvalidDate],
        
        -- Pattern 5: Domain checks
        CASE WHEN src.[Stage] IS NULL THEN 0 WHEN src.[Stage] IN (N'Prospecting', N'Approved', N'Closed Won') THEN 0 ELSE 1 END AS [Stage_IsOutOfDomain],
        
        -- Pattern 6: Range checks
        CASE WHEN src.[CommitmentBalance] IS NULL THEN 0 WHEN TRY_CAST(src.[CommitmentBalance] AS FLOAT) BETWEEN 100 AND 9999999 THEN 0 ELSE 1 END AS [CommitmentBalance_IsOutOfRange],
        
        -- Pattern 7: RI checks
        CASE WHEN src.[OriginatorID] IS NULL THEN 0 WHEN NOT EXISTS (SELECT 1 FROM [dbo].[DimOriginator] WHERE [OriginatorID] = src.[OriginatorID]) THEN 1 ELSE 0 END AS [OriginatorID_IsMissingInDim]
    
    FROM [dbo].[FactLoan] AS src
)
SELECT
    *,
    
    -- Pattern 8: RowHasIssues combiner
    CASE 
        WHEN [LoanID_IsBlank] = 1 OR [LoanID_IsDuplicate] = 1 OR [CommitmentBalance_IsInvalidNumber] = 1 
          OR [CommitmentBalance_IsOutOfRange] = 1 OR [GLDate_IsInvalidDate] = 1 
          OR [Stage_IsOutOfDomain] = 1 OR [OriginatorID_IsMissingInDim] = 1
        THEN 1 
        ELSE 0 
    END AS RowHasIssues,
    
    -- Pattern 9: MaxSeverity
    CASE 
        WHEN [LoanID_IsBlank] = 1 THEN N'Error'
        WHEN [LoanID_IsDuplicate] = 1 THEN N'Error'
        WHEN [OriginatorID_IsMissingInDim] = 1 THEN N'Error'
        WHEN [CommitmentBalance_IsInvalidNumber] = 1 THEN N'Warn'
        WHEN [CommitmentBalance_IsOutOfRange] = 1 THEN N'Warn'
        WHEN [GLDate_IsInvalidDate] = 1 THEN N'Warn'
        WHEN [Stage_IsOutOfDomain] = 1 THEN N'Warn'
        ELSE NULL
    END AS MaxSeverity,
    
    -- Pattern 10: IssueList concatenation
    NULLIF(STUFF(
        CASE WHEN [LoanID_IsBlank] = 1 THEN '; LoanID_IsBlank' ELSE '' END +
        CASE WHEN [LoanID_IsDuplicate] = 1 THEN '; LoanID_IsDuplicate' ELSE '' END +
        CASE WHEN [CommitmentBalance_IsInvalidNumber] = 1 THEN '; CommitmentBalance_IsInvalidNumber' ELSE '' END +
        CASE WHEN [CommitmentBalance_IsOutOfRange] = 1 THEN '; CommitmentBalance_IsOutOfRange' ELSE '' END +
        CASE WHEN [GLDate_IsInvalidDate] = 1 THEN '; GLDate_IsInvalidDate' ELSE '' END +
        CASE WHEN [Stage_IsOutOfDomain] = 1 THEN '; Stage_IsOutOfDomain' ELSE '' END +
        CASE WHEN [OriginatorID_IsMissingInDim] = 1 THEN '; OriginatorID_IsMissingInDim' ELSE '' END,
        1, 2, ''),
    '') AS IssueList

FROM Flags;
GO
```

This VIEW can be queried directly or imported to Power BI for further analysis.

