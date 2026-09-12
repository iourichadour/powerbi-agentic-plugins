#!/usr/bin/env python3
"""Compute read-only test coverage statistics for a semantic model + registry pair.

Usage:
    uv run coverage_report.py --model-dir <path> --registry <MeasureCertification.csv> \
        --output-dir <reports dir> [--json]

Writes `coverage.json` (machine-readable) and `coverage-summary.md` (human-readable) into
--output-dir. Never writes to the registry or the model — this is strictly a read-only report,
separate from `certify_measures.py scan`'s per-measure metadata compliance report (see
../references/certification-registry-schema.md#test-coverage-statistics-and-scan-vs-coverage).
"""
from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _registry_common import read_registry_rows, scan_model_measures  # noqa: E402


def compute_coverage(model_dir: Path, registry_path: Path) -> dict:
    model_measures = scan_model_measures(model_dir)

    rows = []
    if registry_path.exists():
        _, rows = read_registry_rows(registry_path)

    rows_by_measure: dict[str, list[dict]] = {}
    for row in rows:
        rows_by_measure.setdefault(row["MeasureName"], []).append(row)

    untested = sorted(m for m in model_measures if m not in rows_by_measure)
    with_any_row = sorted(m for m in model_measures if m in rows_by_measure)

    def has_row(measure: str, predicate) -> bool:
        return any(predicate(r) for r in rows_by_measure.get(measure, []))

    structural_covered = sorted(
        m for m in model_measures
        if has_row(m, lambda r: r["TestCategory"] == "Structural" and r["Status"] == "Approved")
    )
    developer_covered = sorted(
        m for m in model_measures
        if has_row(m, lambda r: r["TestCategory"] != "Structural" and r["Status"] == "Approved" and r["ApprovalSource"] == "Developer")
    )
    business_covered = sorted(
        m for m in model_measures
        if has_row(m, lambda r: r["TestCategory"] != "Structural" and r["Status"] == "Approved" and r["ApprovalSource"] == "Business")
    )

    breakdown = Counter(
        (r["TestCategory"], r["Status"], r["ApprovalSource"] or "(none)")
        for r in rows
    )

    total = len(model_measures)

    def pct(n: int) -> float:
        return round(100.0 * n / total, 1) if total else 0.0

    return {
        "modelDir": str(model_dir),
        "registry": str(registry_path),
        "totalMeasures": total,
        "untestedMeasures": untested,
        "untestedPct": pct(len(untested)),
        "anyCoveragePct": pct(len(with_any_row)),
        "structuralCoveragePct": pct(len(structural_covered)),
        "developerCertifiedCoveragePct": pct(len(developer_covered)),
        "businessCertifiedCoveragePct": pct(len(business_covered)),
        "breakdown": [
            {"testCategory": k[0], "status": k[1], "approvalSource": k[2], "count": v}
            for k, v in sorted(breakdown.items())
        ],
    }


def render_markdown(coverage: dict) -> str:
    lines = [
        "# Measure Test Coverage Summary",
        "",
        f"- Total measures in model: **{coverage['totalMeasures']}**",
        f"- Untested (zero registry rows): **{coverage['untestedPct']}%** ({len(coverage['untestedMeasures'])})",
        f"- Any registry coverage: **{coverage['anyCoveragePct']}%**",
        f"- Executable Structural coverage: **{coverage['structuralCoveragePct']}%**",
        f"- Developer-certified coverage: **{coverage['developerCertifiedCoveragePct']}%**",
        f"- Business-certified coverage: **{coverage['businessCertifiedCoveragePct']}%**",
        "",
        "> Coverage is a snapshot of the registry, not proof that tests pass. Run `pql-tester run`",
        "> and check `report` mode for pass/fail status.",
        "",
        "## TestCategory × Status × ApprovalSource Breakdown",
        "",
        "| TestCategory | Status | ApprovalSource | Count |",
        "|---|---|---|---|",
    ]
    for row in coverage["breakdown"]:
        lines.append(f"| {row['testCategory']} | {row['status']} | {row['approvalSource']} | {row['count']} |")
    if coverage["untestedMeasures"]:
        lines += ["", "## Untested Measures", ""]
        lines += [f"- {m}" for m in coverage["untestedMeasures"]]
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--registry", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)

    coverage = compute_coverage(args.model_dir, args.registry)

    args.output_dir.mkdir(parents=True, exist_ok=True)
    (args.output_dir / "coverage.json").write_text(json.dumps(coverage, indent=2) + "\n", encoding="utf-8", newline="\n")
    (args.output_dir / "coverage-summary.md").write_text(render_markdown(coverage), encoding="utf-8", newline="\n")

    if args.json:
        print(json.dumps(coverage, indent=2))
    else:
        print(f"Wrote {args.output_dir / 'coverage.json'} and {args.output_dir / 'coverage-summary.md'}")
        print(f"Any coverage: {coverage['anyCoveragePct']}% | Structural: {coverage['structuralCoveragePct']}% | "
              f"Developer: {coverage['developerCertifiedCoveragePct']}% | Business: {coverage['businessCertifiedCoveragePct']}%")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
