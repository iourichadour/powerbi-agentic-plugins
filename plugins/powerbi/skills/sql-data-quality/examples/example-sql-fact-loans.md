# Example — FactLoan Audit View

This walkthrough shows the approval-gated flow for a single SQL Server table.

## 1. Generate rules CSV

Run:

```powershell
powershell -ExecutionPolicy Bypass -File plugins/powerbi/skills/sql-data-quality/scripts/Generate-DQRulesCSV.ps1 -ServerInstance "localhost" -Database "AscentDB" -TableName "FactLoan" -OutFile "documents/dq_rules.generated.csv"
```

The script inspects schema metadata, suggests rules, and writes a CSV for user review.

## 2. Review and approve

Example approved rows:

```csv
RuleId,TableName,ColumnName,RuleType,ExpectedType,AllowBlank,MinValue,MaxValue,AllowedValues,RefTable,RefColumn,ConditionSQL,Severity,Notes
FactLoan_LoanID_KeyNotBlank,FactLoan,LoanID,KeyNotBlank,Text,0,,,,,,,Error,Primary key must be present
FactLoan_LoanID_KeyUnique,FactLoan,LoanID,KeyUnique,Text,0,,,,,,,Error,Detect duplicate loan IDs
FactLoan_CommitmentBalance_TypeNumber,FactLoan,CommitmentBalance,TypeNumber,Number,1,,,,,,,Warn,Amount must be numeric
FactLoan_Stage_Domain,FactLoan,Stage,Domain,Text,1,,,Prospecting|Approved|Closed Won,,,,Warn,Stage must be in the approved domain
```

## 3. Generate audit view DDL after approval

Run:

```powershell
powershell -ExecutionPolicy Bypass -File plugins/powerbi/skills/sql-data-quality/scripts/Generate-DQAuditView.ps1 -CsvPath "documents/dq_rules.generated.csv" -TableFilter "FactLoan" -OutFile "output/FactLoan_DQ_Audit.sql"
```

Generated pattern:

```sql
CREATE OR ALTER VIEW [dbo].[FactLoan_DQ_Audit] AS
WITH Flags AS (
    SELECT
        src.*,
        CASE WHEN src.[LoanID] IS NULL OR LTRIM(RTRIM(CAST(src.[LoanID] AS NVARCHAR(MAX)))) = '' THEN 1 ELSE 0 END AS [LoanID_IsBlank],
        CASE WHEN COUNT(*) OVER (PARTITION BY src.[LoanID]) > 1 THEN 1 ELSE 0 END AS [LoanID_IsDuplicate],
        CASE WHEN src.[CommitmentBalance] IS NULL THEN 0 WHEN TRY_CAST(src.[CommitmentBalance] AS FLOAT) IS NOT NULL THEN 0 ELSE 1 END AS [CommitmentBalance_IsInvalidNumber],
        CASE WHEN src.[Stage] IS NULL THEN 0 WHEN src.[Stage] IN (N'Prospecting', N'Approved', N'Closed Won') THEN 0 ELSE 1 END AS [Stage_IsOutOfDomain]
    FROM [dbo].[FactLoan] AS src
)
SELECT
    *,
    CASE WHEN [LoanID_IsBlank] = 1 OR [LoanID_IsDuplicate] = 1 OR [CommitmentBalance_IsInvalidNumber] = 1 OR [Stage_IsOutOfDomain] = 1 THEN 1 ELSE 0 END AS RowHasIssues,
    CASE WHEN [LoanID_IsBlank] = 1 OR [LoanID_IsDuplicate] = 1 THEN 'Error' WHEN [CommitmentBalance_IsInvalidNumber] = 1 OR [Stage_IsOutOfDomain] = 1 THEN 'Warn' ELSE NULL END AS MaxSeverity,
    NULLIF(STUFF(
        CASE WHEN [LoanID_IsBlank] = 1 THEN '; LoanID_IsBlank' ELSE '' END +
        CASE WHEN [LoanID_IsDuplicate] = 1 THEN '; LoanID_IsDuplicate' ELSE '' END +
        CASE WHEN [CommitmentBalance_IsInvalidNumber] = 1 THEN '; CommitmentBalance_IsInvalidNumber' ELSE '' END +
        CASE WHEN [Stage_IsOutOfDomain] = 1 THEN '; Stage_IsOutOfDomain' ELSE '' END,
        1, 2, ''
    ), '') AS IssueList
FROM Flags;
GO
```

## 4. Use in Power BI

1. Connect Power BI to `[dbo].[FactLoan_DQ_Audit]` with DirectQuery or Import.
2. Filter the exceptions page to `RowHasIssues = 1`.
3. Display `IssueList` and `MaxSeverity` alongside business columns.
4. Use red for `Error` and orange for `Warn`.
