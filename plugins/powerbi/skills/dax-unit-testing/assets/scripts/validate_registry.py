#!/usr/bin/env python3
"""Validate a MeasureCertification.csv registry against the powerbi/dax-unit-testing contract.

Usage:
    uv run validate_registry.py <registry.csv> --model-dir <path-to-semantic-model> [--json]
    uv run validate_registry.py <registry.csv> --schema-only [--json]

See ../references/certification-registry-schema.md for the full rule list. Every violation is
reported using the fixed error-type vocabulary (REGISTRY_INVALID for every rule in this script).

Exit codes:
    0 - no findings (schema-only mode always exits 0 if no findings; the model-existence rule
        is reported as "not evaluated" rather than as a finding)
    1 - one or more REGISTRY_INVALID findings
    2 - usage error (bad arguments, file not found, or unreadable header)
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _registry_common import (  # noqa: E402
    APPROVAL_SOURCES,
    NOT_APPLICABLE,
    PENDING_PLACEHOLDER,
    SEVERITIES,
    STATUSES,
    TEST_CATEGORIES,
    Finding,
    RegistryError,
    is_valid_expected_value,
    is_valid_iso_date_or_na,
    is_valid_tolerance,
    read_registry_rows,
    scan_model_measures,
)


def validate_row(row: dict, row_number: int, model_measures: set[str] | None) -> list[Finding]:
    findings: list[Finding] = []
    measure = row.get("MeasureName", "")
    test_name = row.get("TestName", "")

    def add(error_type: str, message: str) -> None:
        findings.append(Finding(
            error_type=error_type, message=message, measure_name=measure,
            test_name=test_name, row_number=row_number,
        ))

    category = row.get("TestCategory", "")
    status = row.get("Status", "")
    approval_source = row.get("ApprovalSource", "")
    severity = row.get("Severity", "")
    filter_expr = row.get("FilterExpression", "")
    expected_value = row.get("ExpectedValue", "")
    tolerance = row.get("Tolerance", "")
    approved_by = row.get("ApprovedBy", "")
    approved_on = row.get("ApprovedOn", "")
    last_reviewed = row.get("LastReviewed", "")

    if not measure:
        add("REGISTRY_INVALID", "MeasureName is required.")
    if not test_name:
        add("REGISTRY_INVALID", "TestName is required.")

    if category not in TEST_CATEGORIES:
        add("REGISTRY_INVALID", f"TestCategory must be one of {sorted(TEST_CATEGORIES)}, got {category!r}.")
    if status not in STATUSES:
        add("REGISTRY_INVALID", f"Status must be one of {sorted(STATUSES)}, got {status!r}.")
    if severity not in SEVERITIES:
        add("REGISTRY_INVALID", f"Severity must be one of {sorted(SEVERITIES)}, got {severity!r}.")

    # ApprovalSource cross-field rule: Structural <=> Structural.
    if approval_source and approval_source not in APPROVAL_SOURCES:
        add("REGISTRY_INVALID", f"ApprovalSource must be one of {sorted(APPROVAL_SOURCES)}, got {approval_source!r}.")
    if approval_source == "Structural" and category != "Structural":
        add("REGISTRY_INVALID", "ApprovalSource=Structural is reserved for TestCategory=Structural rows.")
    if category == "Structural" and approval_source in ("Developer", "Business"):
        add("REGISTRY_INVALID", "A Structural row must not declare ApprovalSource=Developer or ApprovalSource=Business.")

    # FilterExpression rule: required for non-Structural rows once they leave Pending.
    # (Pending placeholder rows are permitted to leave FilterExpression unset per the
    # sync-never-guesses-a-business-value requirement; enforcing non-empty at Pending would
    # make every freshly-synced measure fail validation before a human ever supplies a value.)
    if category in ("Certification", "Aggregation", "Regression") and status != "Pending":
        if not filter_expr.strip():
            add("REGISTRY_INVALID", f"TestCategory={category} rows require a non-empty FilterExpression once Status is not Pending.")

    # ExpectedValue rule: must be a valid form when Approved; TBD is never valid when Approved.
    if status == "Approved":
        if expected_value == PENDING_PLACEHOLDER:
            add("REGISTRY_INVALID", "ExpectedValue=TBD is not valid on a Status=Approved row.")
        elif not is_valid_expected_value(expected_value):
            add("REGISTRY_INVALID", f"ExpectedValue {expected_value!r} is not numeric, NOT_BLANK, >=0, or >0.")

    if not is_valid_tolerance(tolerance):
        add("REGISTRY_INVALID", f"Tolerance {tolerance!r} must be numeric and >= 0.")

    if status == "Approved":
        if not approval_source:
            add("REGISTRY_INVALID", "Status=Approved rows require an ApprovalSource.")
        elif approval_source == "Structural":
            if approved_by != NOT_APPLICABLE or approved_on != NOT_APPLICABLE:
                add("REGISTRY_INVALID", "ApprovalSource=Structural rows must set ApprovedBy and ApprovedOn to the literal sentinel N/A.")
        elif approval_source in ("Developer", "Business"):
            if not approved_by or approved_by == NOT_APPLICABLE:
                add("REGISTRY_INVALID", f"ApprovalSource={approval_source} rows require a real ApprovedBy identity, not N/A or blank.")
            if not is_valid_iso_date_or_na(approved_on, na_allowed=False):
                add("REGISTRY_INVALID", f"ApprovedOn {approved_on!r} must be a valid ISO date for ApprovalSource={approval_source} rows.")

    if not is_valid_iso_date_or_na(last_reviewed, na_allowed=False):
        add("REGISTRY_INVALID", f"LastReviewed {last_reviewed!r} must be a valid ISO (YYYY-MM-DD) date.")

    if measure and model_measures is not None and measure not in model_measures:
        add("REGISTRY_INVALID", f"MeasureName {measure!r} was not found in the semantic model.")

    return findings


def validate_registry(registry_path: Path, model_dir: Path | None, schema_only: bool) -> tuple[list[Finding], list[str]]:
    _, rows = read_registry_rows(registry_path)

    model_measures: set[str] | None = None
    notes: list[str] = []
    if schema_only:
        notes.append("MeasureName-exists-in-model rule was not evaluated (--schema-only mode).")
    elif model_dir is not None:
        model_measures = scan_model_measures(model_dir)
    else:
        notes.append("MeasureName-exists-in-model rule was not evaluated (no --model-dir supplied).")

    findings: list[Finding] = []
    seen_pairs: dict[tuple[str, str], int] = {}
    for i, row in enumerate(rows, start=1):
        findings.extend(validate_row(row, i, model_measures))
        key = (row.get("MeasureName", ""), row.get("TestName", ""))
        if key in seen_pairs:
            findings.append(Finding(
                error_type="REGISTRY_INVALID",
                message=f"Duplicate (MeasureName, TestName) pair also found at row {seen_pairs[key]}.",
                measure_name=key[0], test_name=key[1], row_number=i,
            ))
        else:
            seen_pairs[key] = i

    return findings, notes


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("registry", type=Path, help="Path to Certification/MeasureCertification.csv")
    parser.add_argument("--model-dir", type=Path, default=None, help="Semantic model project directory (for MeasureName existence check)")
    parser.add_argument("--schema-only", action="store_true", help="Skip the MeasureName-exists-in-model rule; validate everything else")
    parser.add_argument("--json", action="store_true", help="Emit machine-readable JSON instead of a text summary")
    args = parser.parse_args(argv)

    if not args.registry.exists():
        print(f"error: registry file not found: {args.registry}", file=sys.stderr)
        return 2

    try:
        findings, notes = validate_registry(args.registry, args.model_dir, args.schema_only)
    except RegistryError as exc:
        findings, notes = [exc.finding], []

    result = {
        "registry": str(args.registry),
        "schemaOnly": args.schema_only,
        "findingCount": len(findings),
        "findings": [dataclasses_asdict(f) for f in findings],
        "notes": notes,
        "valid": len(findings) == 0,
    }

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        if notes:
            for note in notes:
                print(f"NOTE: {note}")
        if not findings:
            print(f"OK: {args.registry} has no REGISTRY_INVALID findings.")
        else:
            print(f"FAILED: {len(findings)} finding(s) in {args.registry}:")
            for f in findings:
                print(f"  {f}")

    return 0 if not findings else 1


def dataclasses_asdict(finding: Finding) -> dict:
    return {
        "errorType": finding.error_type,
        "message": finding.message,
        "measureName": finding.measure_name,
        "testName": finding.test_name,
        "rowNumber": finding.row_number,
    }


if __name__ == "__main__":
    raise SystemExit(main())
