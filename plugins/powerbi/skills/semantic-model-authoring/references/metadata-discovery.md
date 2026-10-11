# Semantic Model Metadata Discovery — DAX INFO Functions

Read-only DAX queries for metadata exploration using `INFO.VIEW.*` and `INFO.*`
rowsets. Use this reference when discovering model metadata through DAX INFO
functions instead of `powerbi-modeling-mcp` list/get tools. It belongs to the
`semantic-model-authoring` metadata-discovery workflow and is not a
data-consumption workflow.

## Recommended Discovery Order

1. Run the [Scope Estimation Queries](#scope-estimation-queries) to estimate metadata scope (table, column, measure, and relationship counts) before deep discovery.
2. Start with `INFO.VIEW.TABLES()` for a fast table inventory.
3. Expand to `INFO.VIEW.COLUMNS()` and `INFO.VIEW.MEASURES()` for semantic details.
4. Use `INFO.VIEW.RELATIONSHIPS()` to validate joins and filter behavior.
5. Use the deeper patterns only when a required metadata object is not covered by the `INFO.VIEW.*` functions.

## Metadata Object → INFO Function Map

| Metadata Object | Primary INFO functions |
|---|---|
| Model | `INFO.MODEL` |
| Tables | `INFO.VIEW.TABLES` |
| Columns | `INFO.VIEW.COLUMNS`, `INFO.GROUPBYCOLUMNS`, `INFO.RELATEDCOLUMNDETAILS` |
| Measures | `INFO.VIEW.MEASURES`, `INFO.FORMATSTRINGDEFINITIONS`, `INFO.DETAILROWSDEFINITIONS` |
| Relationships | `INFO.VIEW.RELATIONSHIPS` |
| Partitions | `INFO.PARTITIONS`, `INFO.EXPRESSIONS`, `INFO.QUERYGROUPS`, `INFO.REFRESHPOLICIES`, `INFO.DATACOVERAGEDEFINITIONS` |
| Expressions/Parameters | `INFO.EXPRESSIONS` |
| Security roles & permissions | `INFO.ROLES`, `INFO.TABLEPERMISSIONS`, `INFO.COLUMNPERMISSIONS` |
| Hierarchies | `INFO.HIERARCHIES`, `INFO.LEVELS`, `INFO.ATTRIBUTEHIERARCHIES`, `INFO.VARIATIONS` |
| Calculation groups/items | `INFO.CALCULATIONGROUPS`, `INFO.CALCULATIONITEMS` |
| Perspectives | `INFO.PERSPECTIVES`, `INFO.PERSPECTIVETABLES`, `INFO.PERSPECTIVECOLUMNS`, `INFO.PERSPECTIVEHIERARCHIES`, `INFO.PERSPECTIVEMEASURES` |
| Calendars | `INFO.CALENDARS`, `INFO.CALENDARCOLUMNGROUPS`, `INFO.CALENDARCOLUMNREFERENCES` |
| Cultures | `INFO.CULTURES` |
| Object translations | `INFO.OBJECTTRANSLATIONS` |
| Functions | `INFO.USERDEFINEDFUNCTIONS` |
| Dependencies / lineage | `INFO.DEPENDENCIES`, `INFO.CHANGEDPROPERTIES`, `INFO.EXCLUDEDARTIFACTS` |
| Storage internals / size | `INFO.STORAGETABLES`, `INFO.STORAGETABLECOLUMNS`, `INFO.STORAGETABLECOLUMNSEGMENTS`, `INFO.COLUMNSTORAGES`, `INFO.PARTITIONSTORAGES`, `INFO.TABLESTORAGES` |

## Scope Estimation Queries

```dax
// Probe object counts to estimate metadata scope before deep discovery
EVALUATE
ROW(
    "TableCount", COUNTROWS(INFO.VIEW.TABLES()),
    "ColumnCount", COUNTROWS(INFO.VIEW.COLUMNS()),
    "MeasureCount", COUNTROWS(INFO.VIEW.MEASURES()),
    "RelationshipCount", COUNTROWS(INFO.VIEW.RELATIONSHIPS())
)
```

## Narrowing Results (Projection + Filtering)

```dax
// Pull only needed columns for a single table to reduce output volume
EVALUATE
SELECTCOLUMNS(
    FILTER(INFO.VIEW.COLUMNS(), [Table] = "YourTableName"),
    "Column Alias", [Name],
    "DataType", [DataType]
)
```

## Ordering Results

`ORDER BY` must reference the column name as it exists in the query's output,
not the underlying `INFO.*` source column:

- Without `SELECTCOLUMNS`, order by the INFO function's original column name,
  for example `ORDER BY [Name]` on `INFO.VIEW.TABLES()`.
- With `SELECTCOLUMNS`, order by the projection alias, not the original name.

```dax
// Correct: order by the alias defined in SELECTCOLUMNS
EVALUATE
SELECTCOLUMNS(
    FILTER(INFO.VIEW.COLUMNS(), [Table] = "YourTableName"),
    "Column Alias", [Name],
    "DataType", [DataType]
)
ORDER BY [Column Alias] ASC
```

## Dependency Discovery

### Dependency rowset for a DAX query

```dax
// Returns dependency graph for the query payload
DEFINE
VAR _Query = "EVALUATE SUMMARIZECOLUMNS('Date'[Year], 'Product'[Color], ""Sales"", [Sales])"
EVALUATE
INFO.DEPENDENCIES("QUERY", _Query)
```

### Dependency rowset scoped to a measure

```dax
// Adjust values to your model object names
EVALUATE
FILTER(
    INFO.DEPENDENCIES(),
    [OBJECT_TYPE] = "MEASURE"
        && [TABLE] = "Sales"
        && [OBJECT] = "Total Sales"
)
```

### Reverse dependencies

Use this when dependency columns are exposed in the engine rowset:

```dax
EVALUATE
FILTER(
    INFO.DEPENDENCIES(),
    [REFERENCED_OBJECT_TYPE] = "MEASURE"
        && [REFERENCED_TABLE] = "Sales"
        && [REFERENCED_OBJECT] = "Total Sales"
)
```

Dependency rowset column names may vary by engine/version; validate available
fields with an unfiltered probe query first.

## Complete INFO Function Catalog

Only run this query if the required metadata object is not returned by one of
the frequently used functions.

```dax
EVALUATE
SELECTCOLUMNS(
    FILTER(
        INFO.FUNCTIONS(),
        LEFT([FUNCTION_NAME], 5) = "INFO."
    ),
    [FUNCTION_NAME]
)
```

## Reference Queries

```dax
// Detailed model metadata
EVALUATE
INFO.MODEL()
```

```dax
// Partition of a table
EVALUATE
FILTER(INFO.PARTITIONS(), [TableID] == 123)
```

```dax
// Probe output schema of an INFO function (zero data rows)
EVALUATE
TOPN(0, INFO.VIEW.COLUMNS())
```

```dax
// Object translations metadata
EVALUATE
INFO.OBJECTTRANSLATIONS()
```

## Troubleshooting

- **Advanced INFO functions return permission errors** — Start with
  `INFO.VIEW.*` functions for read-oriented discovery; many `INFO.*` functions
  require elevated semantic-model permissions.
- **Metadata output is too large** — Run the scope-estimation query, inspect
  the output schema, and narrow results with projection and filtering.
- **Role memberships are empty or incomplete** — `INFO.ROLEMEMBERSHIPS()` is
  not a reliable source because role members are assigned at the service level.
  Redirect to [Manage role membership documentation](https://learn.microsoft.com/en-us/fabric/security/service-admin-row-level-security#manage-role-membership).
