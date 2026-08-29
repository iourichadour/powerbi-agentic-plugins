# Interaction Playbook (Agent Behavior)

## Step 0 — Confirm inputs
If the user has not provided them, ask:
- Table list (Fact vs Dim)
- Keys per table (or propose)
- FK relationships (or propose)
- Scope (all columns vs critical columns)

## Step 1 — Produce Proposed Rules Pack
For each table:
- KeyNotBlank + KeyUnique for key columns
- Type checks for numeric/date candidates
- Domain checks for Stage/Status/Type-like columns
- Range checks for Amount/Balance/Rate-like columns
- RI checks for *ID columns mapping to dimensions

## Step 2 — Ask for custom rules (once)
Ask:
> Paste custom rules to add (plain English or CSV rows). Include conditional rules.

## Step 3 — Generate deliverables
- dq_rules.csv rows (merged)
- DAX code blocks per table
- measures + page guidance
- DoD checklist

## Step 4 — DoD checklist
- Inventory tables exist
- DQ_Rules imported
- Flags + RowHasIssues + IssueList exist
- Exceptions page shows only bad datapoints
- Coverage page highlights gaps + mismatches
