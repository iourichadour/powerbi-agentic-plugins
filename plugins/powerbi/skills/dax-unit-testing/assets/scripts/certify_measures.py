#!/usr/bin/env python3
"""Model scan, registry sync, developer/business certification, and legacy migration.

Subcommands:
    scan            Read-only per-measure metadata compliance report. No writes.
    sync            Auto-generate+approve Structural rows, append Pending Certification
                     placeholders, and flag (never delete) orphaned rows. Writes the registry only.
    certify         Record an explicit developer- or business-approved baseline for one row.
    migrate-legacy  Import an 11-column legacy registry into the 14-column schema.

See ../references/certification-registry-schema.md and ../references/legacy-registry-migration.md.
"""
from __future__ import annotations

import argparse
import dataclasses
import datetime as _dt
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _registry_common import (  # noqa: E402
    COLUMNS,
    NOT_APPLICABLE,
    PENDING_PLACEHOLDER,
    Finding,
    RegistryError,
    read_legacy_registry_rows,
    read_registry_rows,
    scan_model_measure_metadata,
    scan_model_measures,
    write_registry_rows,
)

REQUIRED_METADATA_FIELDS = ("description", "format_string", "display_folder")


# --- scan ------------------------------------------------------------------------

def cmd_scan(args: argparse.Namespace) -> int:
    metadata = scan_model_measure_metadata(args.model_dir)
    registry_measures: dict[str, list[dict]] = {}
    if args.registry.exists():
        _, rows = read_registry_rows(args.registry)
        for row in rows:
            registry_measures.setdefault(row["MeasureName"], []).append(row)

    report = []
    findings: list[Finding] = []
    for name in sorted(metadata):
        meta = metadata[name]
        rows = registry_measures.get(name, [])
        has_structural = any(r["TestCategory"] == "Structural" for r in rows)
        has_certification = any(r["TestCategory"] in ("Certification", "Aggregation", "Regression") for r in rows)
        missing_metadata = [f for f in REQUIRED_METADATA_FIELDS if not getattr(meta, f)]
        if missing_metadata:
            findings.append(Finding(
                error_type="METADATA_INCOMPLETE",
                message=f"Missing: {', '.join(missing_metadata)}",
                measure_name=name,
            ))
        report.append({
            "measureName": name,
            "homeTable": meta.home_table,
            "description": meta.description,
            "formatString": meta.format_string,
            "displayFolder": meta.display_folder,
            "hasStructuralRow": has_structural,
            "hasCertificationRow": has_certification,
            "registryRowCount": len(rows),
        })

    result = {"measures": report, "findings": [dataclasses.asdict(f) for f in findings]}
    print(json.dumps(result, indent=2) if args.json else _format_scan_text(result))
    return 0


def _format_scan_text(result: dict) -> str:
    lines = [f"Scanned {len(result['measures'])} measure(s):"]
    for m in result["measures"]:
        flags = []
        if not m["hasStructuralRow"]:
            flags.append("no-structural-row")
        if not m["hasCertificationRow"]:
            flags.append("no-certification-row")
        lines.append(f"  {m['measureName']} [{m['homeTable']}] rows={m['registryRowCount']} {' '.join(flags)}")
    if result["findings"]:
        lines.append(f"{len(result['findings'])} METADATA_INCOMPLETE finding(s):")
        for f in result["findings"]:
            lines.append(f"  [{f['error_type']}] {f['measure_name']}: {f['message']}")
    return "\n".join(lines)


# --- sync ------------------------------------------------------------------------

def cmd_sync(args: argparse.Namespace) -> int:
    as_of = args.as_of_date or _dt.date.today().isoformat()
    model_measures = scan_model_measures(args.model_dir)

    if args.registry.exists():
        _, rows = read_registry_rows(args.registry)
    else:
        rows = []

    rows_by_measure: dict[str, list[dict]] = {}
    for row in rows:
        rows_by_measure.setdefault(row["MeasureName"], []).append(row)

    added: list[dict] = []
    orphaned: list[dict] = []

    for measure in sorted(model_measures):
        existing = rows_by_measure.get(measure, [])
        if not any(r["TestCategory"] == "Structural" for r in existing):
            new_row = _structural_row(measure, as_of)
            rows.append(new_row)
            rows_by_measure.setdefault(measure, []).append(new_row)
            added.append(new_row)
        if not any(r["TestCategory"] in ("Certification", "Aggregation", "Regression") for r in existing):
            new_row = _pending_certification_row(measure, as_of)
            rows.append(new_row)
            rows_by_measure.setdefault(measure, []).append(new_row)
            added.append(new_row)

    for row in rows:
        if row["MeasureName"] not in model_measures:
            orphaned.append(row)

    write_registry_rows(args.registry, rows)

    result = {
        "registry": str(args.registry),
        "addedRows": [{"measureName": r["MeasureName"], "testName": r["TestName"], "testCategory": r["TestCategory"]} for r in added],
        "orphanedRows": [{"measureName": r["MeasureName"], "testName": r["TestName"]} for r in orphaned],
    }
    print(json.dumps(result, indent=2) if args.json else (
        f"Added {len(added)} row(s). {len(orphaned)} orphaned row(s) flagged (not deleted)."
    ))
    return 0


def _structural_row(measure: str, as_of: str) -> dict:
    return {
        "MeasureName": measure,
        "TestName": f"{measure} Structural Test",
        "TestCategory": "Structural",
        "FilterExpression": "",
        "ExpectedValue": "NOT_BLANK",
        "Tolerance": "0",
        "Owner": NOT_APPLICABLE,
        "Status": "Approved",
        "ApprovalSource": "Structural",
        "ApprovedBy": NOT_APPLICABLE,
        "ApprovedOn": NOT_APPLICABLE,
        "Severity": "Major",
        "RequirementId": "",
        "LastReviewed": as_of,
    }


def _pending_certification_row(measure: str, as_of: str) -> dict:
    return {
        "MeasureName": measure,
        "TestName": f"{measure} Certification Test",
        "TestCategory": "Certification",
        "FilterExpression": "",
        "ExpectedValue": PENDING_PLACEHOLDER,
        "Tolerance": "0",
        "Owner": PENDING_PLACEHOLDER,
        "Status": "Pending",
        "ApprovalSource": "",
        "ApprovedBy": "",
        "ApprovedOn": "",
        "Severity": "Major",
        "RequirementId": PENDING_PLACEHOLDER,
        "LastReviewed": as_of,
    }


# --- certify (explicit developer/business baseline) --------------------------------

def cmd_certify(args: argparse.Namespace) -> int:
    _, rows = read_registry_rows(args.registry)
    match = None
    for row in rows:
        if row["MeasureName"] == args.measure and row["TestName"] == args.test_name:
            match = row
            break
    if match is None:
        print(f"error: no row found for MeasureName={args.measure!r} TestName={args.test_name!r}", file=sys.stderr)
        return 2
    if args.approval_source == "Structural":
        print("error: --approval-source Structural cannot be set via `certify`; use `sync`.", file=sys.stderr)
        return 2

    as_of = args.approved_on or _dt.date.today().isoformat()
    match["FilterExpression"] = args.filter_expression if args.filter_expression is not None else match["FilterExpression"]
    match["ExpectedValue"] = args.expected_value
    match["Owner"] = args.owner
    match["Tolerance"] = str(args.tolerance) if args.tolerance is not None else match["Tolerance"]
    match["Status"] = "Approved"
    match["ApprovalSource"] = args.approval_source
    match["ApprovedBy"] = args.approved_by
    match["ApprovedOn"] = as_of
    match["LastReviewed"] = as_of

    write_registry_rows(args.registry, rows)
    print(f"Certified {args.measure!r}/{args.test_name!r} as Status=Approved, ApprovalSource={args.approval_source}.")
    return 0


# --- migrate-legacy ------------------------------------------------------------------

def cmd_migrate_legacy(args: argparse.Namespace) -> int:
    _, legacy_rows = read_legacy_registry_rows(args.legacy_registry)

    mapping: dict[str, dict] = {}
    if args.mapping:
        mapping = json.loads(Path(args.mapping).read_text(encoding="utf-8"))

    migrated: list[dict] = []
    blocked: list[Finding] = []

    for row in legacy_rows:
        new_row = {col: row.get(col, "") for col in COLUMNS}
        key = f"{row['MeasureName']}::{row['TestName']}"

        if row["Status"] != "Approved":
            # Pending/Retired rows carry over unchanged; approval-audit columns stay blank.
            new_row["ApprovalSource"] = ""
            new_row["ApprovedBy"] = ""
            new_row["ApprovedOn"] = ""
            migrated.append(new_row)
            continue

        if row["TestCategory"] == "Structural":
            new_row["ApprovalSource"] = "Structural"
            new_row["ApprovedBy"] = NOT_APPLICABLE
            new_row["ApprovedOn"] = NOT_APPLICABLE
            migrated.append(new_row)
            continue

        # Non-Structural Approved row: requires an explicit mapping; never inferred.
        row_mapping = mapping.get(key)
        if not row_mapping or "approvalSource" not in row_mapping or row_mapping["approvalSource"] not in ("Developer", "Business"):
            blocked.append(Finding(
                error_type="REGISTRY_INVALID",
                message=(
                    f"Legacy row {key} is Status=Approved with TestCategory={row['TestCategory']} but has no "
                    "explicit approvalSource mapping; migration refuses to guess Developer or Business."
                ),
                measure_name=row["MeasureName"], test_name=row["TestName"],
            ))
            continue

        new_row["ApprovalSource"] = row_mapping["approvalSource"]
        new_row["ApprovedBy"] = row_mapping.get("approvedBy", "")
        new_row["ApprovedOn"] = row_mapping.get("approvedOn", "")
        migrated.append(new_row)

    if blocked:
        print(f"Migration blocked: {len(blocked)} ambiguous approved row(s) require an explicit mapping:", file=sys.stderr)
        for f in blocked:
            print(f"  {f}", file=sys.stderr)
        return 1

    write_registry_rows(args.output, migrated)
    print(f"Migrated {len(migrated)} row(s) to {args.output}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    p_scan = sub.add_parser("scan", help="Read-only metadata compliance report")
    p_scan.add_argument("--model-dir", type=Path, required=True)
    p_scan.add_argument("--registry", type=Path, required=True)
    p_scan.add_argument("--json", action="store_true")
    p_scan.set_defaults(func=cmd_scan)

    p_sync = sub.add_parser("sync", help="Reconcile registry against the model")
    p_sync.add_argument("--model-dir", type=Path, required=True)
    p_sync.add_argument("--registry", type=Path, required=True)
    p_sync.add_argument("--as-of-date", type=str, default=None, help="Override today's date (testing only)")
    p_sync.add_argument("--json", action="store_true")
    p_sync.set_defaults(func=cmd_sync)

    p_certify = sub.add_parser("certify", help="Record an explicit developer/business baseline")
    p_certify.add_argument("--registry", type=Path, required=True)
    p_certify.add_argument("--measure", required=True)
    p_certify.add_argument("--test-name", required=True)
    p_certify.add_argument("--expected-value", required=True)
    p_certify.add_argument("--filter-expression", default=None)
    p_certify.add_argument("--owner", required=True)
    p_certify.add_argument("--tolerance", type=float, default=None)
    p_certify.add_argument("--approval-source", required=True, choices=["Developer", "Business"])
    p_certify.add_argument("--approved-by", required=True)
    p_certify.add_argument("--approved-on", default=None)
    p_certify.set_defaults(func=cmd_certify)

    p_migrate = sub.add_parser("migrate-legacy", help="Import an 11-column legacy registry")
    p_migrate.add_argument("legacy_registry", type=Path)
    p_migrate.add_argument("--output", type=Path, required=True)
    p_migrate.add_argument("--mapping", type=Path, default=None, help="JSON file: {'Measure::Test': {'approvalSource': 'Business', 'approvedBy': '...', 'approvedOn': '...'}}")
    p_migrate.set_defaults(func=cmd_migrate_legacy)

    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except RegistryError as exc:
        print(str(exc.finding), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
