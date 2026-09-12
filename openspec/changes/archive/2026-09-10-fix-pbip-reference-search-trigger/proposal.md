## Why

Developers asking to "find all references to `Region` from table `X`" or "where is this field used" are not reliably routed to the bundled `report_reference_scan.py` scanner in `powerbi-report-authoring` — the skill's discovery metadata frames the scanner mainly as a rename-impact tool, not a general reference-search capability, so these requests fall through to generic text search. Separately, when the scanner *is* invoked with both a table term and a field term, it returns two independent hit lists; nothing in the workflow correlates a table match and a field match into a single qualified `Table[Field]` reference, so a report that only contains the table name (or only a same-named field from an unrelated table) can be mis-reported as evidence the specific field is used there.

## What Changes

- Expand the `powerbi-report-authoring` skill's frontmatter `description` with explicit reference-search trigger phrases ("find all references", "where is this field used", "find reports using", "scan PBIP dependencies") so the skill is discoverable on the first prompt for reference-search requests, not only for rename/removal requests.
- Add an explicit reference-search routing section to the skill body, read before the general authoring workflow, directing table+field reference requests to `report_reference_scan.ps1`/`report_reference_scan.py` with the table/entity and field/measure passed as separate scanner terms.
- Document (and where needed adjust) an explicit PowerShell array invocation for multi-term scans (`$terms = @('<Table>', '<Field>')`) to avoid a bare multi-value `-Terms` argument binding to another parameter such as `-MaxItems`.
- Define a correlation step, applied after the scanner returns hits for both the table term and the field term: classify each result as an **exact qualified reference** (the field appears within the scope of the same table/entity in the same PBIR artifact or the same TMDL object), a **table-only reference** (the table/entity matches but the field term does not co-occur in that artifact), or an **unrelated match** (the field term matches a same-named field/column that is not part of the requested table). Report these three categories separately instead of merging table and field hits into one list.
- Update the result-interpretation guidance so a table-only match is never presented as proof the requested field is used, and same-named fields from other tables are called out as likely-unrelated rather than silently included.

## Capabilities

### New Capabilities
- `powerbi/pbip-reference-search`: Discovery/triggering contract and table-to-field correlation contract for the local PBIP reference-search workflow (skill routing plus result classification), independent of the underlying scanner's implementation.

### Modified Capabilities
<!-- none: no existing archived main spec yet covers reference-search triggering or correlation behavior -->

## Impact

- Modified: `plugins/powerbi/skills/powerbi-report-authoring/SKILL.md` (frontmatter `description`, new routing section, result-interpretation guidance).
- Reviewed/possibly modified: `plugins/powerbi/skills/powerbi-report-authoring/scripts/report_reference_scan.ps1` and `report_reference_scan.py` (multi-term array handling; hit data needed to support correlation, e.g. table/entity context already attached to report hits).
- No changes to PBIP reports, semantic models, or the scanner's read-only scanning behavior; this is a skill-discovery and result-interpretation change, not a rewrite of the scanner engine.
- Out of scope: the separate, not-yet-applied `add-python-powerbi-dependency-checking` change, which proposes a full cross-model dependency graph; this change keeps the existing term-oriented scanner and fixes its triggering and reporting instead.
