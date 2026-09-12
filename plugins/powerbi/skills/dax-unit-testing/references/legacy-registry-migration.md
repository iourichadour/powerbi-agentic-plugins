# Legacy Registry Migration

Some existing DAX Query View testing setups (including the external reference implementation this
skill is generalized from) use an **11-column legacy schema** that predates the approval-audit
columns (`ApprovalSource`, `ApprovedBy`, `ApprovedOn`). This document defines the verified legacy
schema and the only supported migration path onto the 14-column contract in
[certification-registry-schema.md](certification-registry-schema.md).

## Legacy 11-Column Schema

```
MeasureName, TestName, TestCategory, FilterExpression, ExpectedValue, Tolerance, Owner, Status, Severity, RequirementId, LastReviewed
```

This is the current 14-column schema with `ApprovalSource`, `ApprovedBy`, and `ApprovedOn` removed.
Every other column has the same meaning and the same permitted values as in
[certification-registry-schema.md](certification-registry-schema.md).

## Why Migration Cannot Be Automatic for Every Row

The legacy schema has no way to record **who or what** approved a `Status=Approved` row. Silently
promoting every legacy `Approved` row to a specific `ApprovalSource` would fabricate an audit trail
that never existed — the migration path must never guess whether an approval was structural,
developer, or business in origin.

## Migration Rules

### 1. Structural rows can be mapped automatically

**WHEN** a legacy row has `Status=Approved` **and** `TestCategory=Structural`
**THEN** migration MAY set `ApprovalSource=Structural` automatically, and SHALL set both
`ApprovedBy` and `ApprovedOn` to the literal sentinel `N/A`.

This is safe because `Structural` rows never carry business meaning in the first place — their
approval provenance is unambiguous by category alone (see the
`ApprovalSource=Structural` ⇔ `TestCategory=Structural` cross-field rule in
[certification-registry-schema.md](certification-registry-schema.md#approvalsource-audit-trail)).

### 2. Ambiguous approved rows are blocked, not guessed

**WHEN** a legacy row is `Status=Approved`, `TestCategory` is `Certification`/`Aggregation`/
`Regression`, and no explicit provenance mapping was supplied for that row
**THEN** migration SHALL stop with a clear migration error identifying the row (`MeasureName` +
`TestName`) and SHALL NOT label it `ApprovalSource=Developer` or `ApprovalSource=Business`.

To unblock such a row, the person running the migration must explicitly state, per row (or per a
matching rule such as "all rows with `Owner=Finance` are business-approved"), whether the existing
approval was a developer baseline or a business certification, and supply an `ApprovedBy`/
`ApprovedOn` pair. Migration then writes exactly what was supplied — it never infers a name or date
on its own.

### 3. Pending and Retired rows carry over unchanged

**WHEN** a legacy row's `Status` is `Pending` or `Retired`
**THEN** migration SHALL preserve every existing value and the `Status` itself, add the three new
columns, and leave `ApprovalSource`/`ApprovedBy`/`ApprovedOn` blank (not `N/A` — `N/A` is reserved
for `Structural` approvals) since these rows are not currently eligible for generation or execution
regardless.

## Migration Output

The migration path is exposed through `certify_measures.py`'s legacy-import mode (see the script's
own `--help`), which:

1. Reads the legacy 11-column file.
2. Applies rule 1 automatically to every `Structural`/`Approved` row.
3. Applies rule 3 automatically to every `Pending`/`Retired` row.
4. For every remaining `Approved` non-Structural row, requires an explicit per-row (or per-rule)
   provenance mapping supplied by the caller; refuses to proceed if any such row is left
   unmapped, and reports each unmapped row individually.
5. Writes the resulting 14-column `Certification/MeasureCertification.csv`, ready for
   `validate_registry.py`.

## Fixture Coverage

Migration fixtures cover, at minimum:

- A `Structural`/`Approved` legacy row → auto-mapped to `ApprovalSource=Structural`,
  `ApprovedBy=N/A`, `ApprovedOn=N/A`.
- A `Certification`/`Approved` legacy row with no supplied provenance → migration stops with an
  explicit per-row error, and the row is not written as `Developer` or `Business`.
- A `Certification`/`Approved` legacy row with an explicit supplied mapping (e.g.
  `ApprovalSource=Business`, `ApprovedBy=jane.doe@example.com`, `ApprovedOn=2025-01-15`) → migration
  writes exactly the supplied values.
- A `Pending` legacy row → carried over with `Status=Pending` and no approval-audit values filled
  in.
- A `Retired` legacy row → carried over with `Status=Retired` and no approval-audit values filled
  in.
