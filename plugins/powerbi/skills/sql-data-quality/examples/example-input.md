# Example Input

Use this input when demonstrating the skill's approval-gated workflow.

## User request

```text
Validate FactLoan and FactPayment in SQL Server.
Server: localhost
Database: AscentDB
Schema: dbo
Generate the rules CSV for review first. Do not generate audit views until I approve.
```

## Expected skill behavior

1. Inspect each table through MSSQL MCP when available, otherwise ask the user for schema details.
2. Auto-generate `documents/dq_rules.generated.csv` with suggested checks and `Severity` values.
3. Present the proposed rules to the user for review.
4. Wait for explicit approval.
5. Generate `CREATE OR ALTER VIEW` DDL only after the user approves the CSV.

## Review prompt template

```text
Generated 12 rules for FactLoan and 8 rules for FactPayment.

Please review the proposed checks. You can:
- approve them as-is
- edit severity, bounds, allowed values, or notes
- add or remove rules

Approve these rules and proceed to audit view generation? [Yes / No / Edit]
```
