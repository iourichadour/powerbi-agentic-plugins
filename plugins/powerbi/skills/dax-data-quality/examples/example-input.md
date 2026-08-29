# Example Input

Paste something like this when running the skill:

```text
Fact_Deals: DealID (key), CustomerID (FK DimCustomer), CloseDate (FK DimDate), Amount, Stage
DimCustomer: CustomerID (key), CustomerName, Email, Status
DimDate: Date (key)
```

Then add custom rules:
- Fact_Deals[Amount] must be >= 0
- If Fact_Deals[Stage] = 'Closed Won' then Fact_Deals[CloseDate] is required
- DimCustomer[Email] must contain '@'
