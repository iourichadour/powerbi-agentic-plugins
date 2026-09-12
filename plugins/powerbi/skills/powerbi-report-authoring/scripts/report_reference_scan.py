#!/usr/bin/env python3
"""
Scan semantic model + report references for one or more Power BI entities.

Output sections:
1) Semantic Model References - records, calc columns, measures
2) Reports - Page, Visual

Examples:
    py plugins/powerbi/skills/powerbi-report-authoring/scripts/report_reference_scan.py --terms Sales
    py plugins/powerbi/skills/powerbi-report-authoring/scripts/report_reference_scan.py --terms Sales Amount --json

This scanner reads saved PBIP/TMDL/PBIR files on disk. It does not inspect
unsaved changes or service-only model state.

Reviewed source SHA-256:
95D04766D5765C5B35ACA79AC5AFB50F0A6A90FE7A93E6E43FA783D2918F1BD6
"""

from __future__ import annotations

import argparse
from contextlib import redirect_stdout
import json
import re
import sys
from collections import defaultdict
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any


@dataclass
class SemanticHit:
    file: str
    table: str
    object_type: str
    object_name: str
    line: int
    line_text: str


@dataclass
class ReportHit:
    report: str
    file: str
    line: int
    match_type: str
    page: str
    visual: str
    visual_internal: str
    visual_tag: str
    line_text: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Scan semantic model and report references by entity name."
    )
    parser.add_argument(
        "--root",
        default="pbi",
        help="Root directory containing *.Report and *.SemanticModel folders (default: pbi)",
    )
    parser.add_argument(
        "--terms",
        nargs="+",
        required=True,
        help="One or more entity/table names to scan",
    )
    output_group = parser.add_mutually_exclusive_group()
    output_group.add_argument(
        "--json",
        action="store_true",
        help="Emit JSON instead of text output",
    )
    parser.add_argument(
        "--max-items",
        type=int,
        default=0,
        help="Max detailed rows per section/report in text mode (default: all, use 0 for all)",
    )
    output_group.add_argument(
        "--output",
        default="",
        help="Optional markdown output file path (UTF-8). If omitted, writes to stdout.",
    )
    return parser.parse_args()


def find_semantic_model_dirs(root: Path) -> list[Path]:
    return sorted(
        [p for p in root.iterdir() if p.is_dir() and p.name.endswith(".SemanticModel")],
        key=lambda p: p.name.lower(),
    )


def find_report_dirs(root: Path) -> list[Path]:
    return sorted(
        [p for p in root.iterdir() if p.is_dir() and p.name.endswith(".Report")],
        key=lambda p: p.name.lower(),
    )


def compile_term_pattern(term: str) -> re.Pattern[str]:
    escaped = re.escape(term)
    return re.compile(rf"'{escaped}'\s*\[|\b{escaped}\b")


def compile_entity_json_pattern(term: str) -> re.Pattern[str]:
    escaped = re.escape(term)
    return re.compile(rf'"Entity"\s*:\s*"{escaped}"')


def compile_property_json_pattern(term: str) -> re.Pattern[str]:
    escaped = re.escape(term)
    return re.compile(rf'"Property"\s*:\s*"{escaped}"')


def compile_queryref_json_pattern(term: str) -> re.Pattern[str]:
    escaped = re.escape(term)
    # Match both forms:
    # 1) term as table prefix: "Funded.SomeColumn"
    # 2) term as column/measure suffix: "SomeTable.CurrentPortfolioAmount_30"
    # 3) exact term (rare but supported): "SomeName"
    return re.compile(
        rf'"queryRef"\s*:\s*"(?:(?:{escaped}(?:\.[^\"]+)?)|(?:[^\"]+\.{escaped}))"'
    )


def parse_tmdl_for_semantic_hits(file_path: Path, term: str) -> list[SemanticHit]:
    hits: list[SemanticHit] = []
    pattern = compile_term_pattern(term)

    current_table = ""
    current_object_type = ""
    current_object_name = ""

    table_re = re.compile(r"^\s*table\s+'?([^']+)'?\s*$")
    measure_re = re.compile(r"^\s*measure\s+'?([^'=]+)'?\s*=")
    calc_column_re = re.compile(r"^\s*column\s+'?([^'=]+)'?\s*=")
    regular_column_re = re.compile(r"^\s*column\s+'?([^'=]+)'?\s*$")

    lines = file_path.read_text(encoding="utf-8", errors="ignore").splitlines()

    for i, line in enumerate(lines, start=1):
        m_table = table_re.match(line)
        if m_table:
            current_table = m_table.group(1).strip()
            current_object_type = "table"
            current_object_name = current_table

        m_measure = measure_re.match(line)
        if m_measure:
            current_object_type = "measure"
            current_object_name = m_measure.group(1).strip().strip("'")

        m_calc = calc_column_re.match(line)
        if m_calc:
            current_object_type = "calc_column"
            current_object_name = m_calc.group(1).strip().strip("'")
        else:
            m_col = regular_column_re.match(line)
            if m_col:
                current_object_type = "column"
                current_object_name = m_col.group(1).strip().strip("'")

        if pattern.search(line):
            obj_type = current_object_type
            if obj_type == "column":
                obj_type = "record"
            elif obj_type == "table":
                obj_type = "record"
            elif obj_type not in {"measure", "calc_column"}:
                obj_type = "record"

            rel_file = file_path.as_posix()
            hits.append(
                SemanticHit(
                    file=rel_file,
                    table=current_table,
                    object_type=obj_type,
                    object_name=current_object_name,
                    line=i,
                    line_text=line.strip(),
                )
            )

    return hits


def load_report_page_visual_lookup(report_dir: Path) -> tuple[dict[str, str], dict[str, str], dict[str, str]]:
    page_lookup: dict[str, str] = {}
    visual_lookup: dict[str, str] = {}
    visual_tag_lookup: dict[str, str] = {}

    pages_root = report_dir / "definition" / "pages"
    if not pages_root.exists():
        return page_lookup, visual_lookup, visual_tag_lookup

    for page_json in pages_root.rglob("page.json"):
        page_folder = page_json.parent.name
        page_name = page_folder
        try:
            data = json.loads(page_json.read_text(encoding="utf-8", errors="ignore"))
            page_name = str(data.get("displayName") or data.get("name") or page_folder)
        except Exception:
            pass
        page_lookup[page_folder] = page_name

    for visual_json in pages_root.rglob("visual.json"):
        visual_id = visual_json.parent.name
        visual_name = visual_id
        visual_tag = visual_id
        try:
            data = json.loads(visual_json.read_text(encoding="utf-8", errors="ignore"))
            name_value = data.get("name")
            if isinstance(name_value, str) and name_value.strip():
                visual_tag = name_value.strip()
            visual_name = extract_visual_name(data) or visual_id
        except Exception:
            pass
        visual_lookup[visual_id] = visual_name
        visual_tag_lookup[visual_id] = visual_tag

    return page_lookup, visual_lookup, visual_tag_lookup


def extract_visual_name(data: dict[str, Any]) -> str | None:
    for key in ("displayName",):
        value = data.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()

    visual = data.get("visual")
    if isinstance(visual, dict):
        vtype = visual.get("visualType")
        if isinstance(vtype, str) and vtype.strip():
            # Keep searching for something friendlier first.
            visual_type = vtype.strip()
        else:
            visual_type = ""
    else:
        visual_type = ""

    # Common PBIR title location: visualContainerObjects.title[*].properties.text.expr.Literal.Value
    title = extract_title_from_objects(data.get("visual", {}).get("visualContainerObjects"))
    if not title:
        # Some visuals carry title in visual.objects.title
        title = extract_title_from_objects(data.get("visual", {}).get("objects"))
    if title:
        return title

    # Fallback to the first native/display query reference.
    query_label = extract_query_label(data)
    if query_label:
        return query_label

    if visual_type:
        return visual_type

    # Use root "name" only as a last resort (often this is just a hash-like tag).
    value = data.get("name")
    if isinstance(value, str) and value.strip():
        return value.strip()

    return None


def extract_title_from_objects(objects: Any) -> str | None:
    if not isinstance(objects, dict):
        return None

    title = objects.get("title")
    if not isinstance(title, list) or not title:
        return None

    first = title[0]
    if not isinstance(first, dict):
        return None

    properties = first.get("properties")
    if not isinstance(properties, dict):
        return None

    text = properties.get("text")
    if not isinstance(text, dict):
        return None

    expr = text.get("expr")
    if not isinstance(expr, dict):
        return None

    literal = expr.get("Literal")
    if not isinstance(literal, dict):
        return None

    value = literal.get("Value")
    if isinstance(value, str):
        return value.strip("'\"").strip() or None

    return None


def extract_query_label(data: dict[str, Any]) -> str | None:
    visual = data.get("visual")
    if not isinstance(visual, dict):
        return None

    query = visual.get("query")
    if not isinstance(query, dict):
        return None

    query_state = query.get("queryState")
    if not isinstance(query_state, dict):
        return None

    for role in ("Values", "Y", "X", "Category", "Rows", "Columns", "Tooltips"):
        bucket = query_state.get(role)
        if not isinstance(bucket, dict):
            continue
        projections = bucket.get("projections")
        if not isinstance(projections, list):
            continue
        for projection in projections:
            if not isinstance(projection, dict):
                continue
            for key in ("displayName", "nativeQueryRef", "queryRef"):
                label = projection.get(key)
                if isinstance(label, str) and label.strip():
                    return label.strip()

    return None


def extract_page_visual_context(
    file_path: Path,
    page_lookup: dict[str, str],
    visual_lookup: dict[str, str],
    visual_tag_lookup: dict[str, str],
) -> tuple[str, str, str, str]:
    parts = file_path.as_posix().split("/")

    page = "(n/a)"
    visual = "(n/a)"
    visual_internal = "(n/a)"
    visual_tag = "(n/a)"

    if "pages" in parts:
        idx = parts.index("pages")
        if idx + 1 < len(parts):
            page_id = parts[idx + 1]
            page = page_lookup.get(page_id, page_id)

    if "visuals" in parts:
        idx = parts.index("visuals")
        if idx + 1 < len(parts):
            visual_id = parts[idx + 1]
            visual_internal = visual_id
            visual = visual_lookup.get(visual_id, visual_id)
            visual_tag = visual_tag_lookup.get(visual_id, visual_id)

    return page, visual, visual_internal, visual_tag


def scan_reports_for_term(report_dir: Path, term: str) -> list[ReportHit]:
    hits: list[ReportHit] = []
    report_patterns: list[tuple[str, re.Pattern[str]]] = [
        ("Entity", compile_entity_json_pattern(term)),
        ("Property", compile_property_json_pattern(term)),
        ("queryRef", compile_queryref_json_pattern(term)),
    ]
    page_lookup, visual_lookup, visual_tag_lookup = load_report_page_visual_lookup(report_dir)

    for json_file in report_dir.rglob("*.json"):
        lines = json_file.read_text(encoding="utf-8", errors="ignore").splitlines()
        for i, line in enumerate(lines, start=1):
            matched_types = [name for name, pattern in report_patterns if pattern.search(line)]
            if matched_types:
                page, visual, visual_internal, visual_tag = extract_page_visual_context(
                    json_file,
                    page_lookup,
                    visual_lookup,
                    visual_tag_lookup,
                )
                hits.append(
                    ReportHit(
                        report=report_dir.name,
                        file=json_file.as_posix(),
                        line=i,
                        match_type=",".join(matched_types),
                        page=page,
                        visual=visual,
                        visual_internal=visual_internal,
                        visual_tag=visual_tag,
                        line_text=line.strip(),
                    )
                )

    return hits


def scan_semantic_models(root: Path, term: str) -> dict[str, list[SemanticHit]]:
    categorized: dict[str, list[SemanticHit]] = {
        "record": [],
        "calc_column": [],
        "measure": [],
    }

    semantic_dirs = find_semantic_model_dirs(root)
    for sem_dir in semantic_dirs:
        definition_dir = sem_dir / "definition"
        if not definition_dir.exists():
            continue
        tables_dir = definition_dir / "tables"
        for tmdl_file in definition_dir.rglob("*.tmdl"):
            for hit in parse_tmdl_for_semantic_hits(tmdl_file, term):
                if tables_dir not in tmdl_file.parents:
                    hit.table = ""
                    hit.object_type = "record"
                    hit.object_name = ""
                categorized[hit.object_type].append(hit)

    return categorized


def scan_reports(root: Path, term: str) -> list[ReportHit]:
    all_hits: list[ReportHit] = []
    for report_dir in find_report_dirs(root):
        all_hits.extend(scan_reports_for_term(report_dir, term))
    return all_hits


def clamp_limit(max_items: int, total: int) -> int:
    if max_items <= 0:
        return total
    return min(max_items, total)


def md_cell(value: Any) -> str:
    text = "" if value is None else str(value)
    return text.replace("\\", "\\\\").replace("|", "\\|").replace("\n", " ").strip()


def slugify(value: str) -> str:
    text = value.lower().strip()
    text = re.sub(r"[^a-z0-9\s-]", "", text)
    text = re.sub(r"\s+", "-", text)
    text = re.sub(r"-+", "-", text)
    return text or "section"


def print_semantic_table(entries: list[SemanticHit], max_items: int) -> None:
    shown = clamp_limit(max_items, len(entries))
    if shown == 0:
        print("_No matches._")
        return

    print("| Table | Object | File | Line |")
    print("|---|---|---|---:|")
    for hit in entries[:shown]:
        print(
            f"| {md_cell(hit.table)} | {md_cell(hit.object_name)} | {md_cell(hit.file)} | {hit.line} |"
        )
    if shown < len(entries):
        print(f"\n_Omitted {len(entries) - shown} more rows. Use --max-items 0 to show all._")


def print_report_table(entries: list[ReportHit], max_items: int) -> None:
    shown = clamp_limit(max_items, len(entries))
    if shown == 0:
        print("_No matches._")
        return

    print("| Match | Page | Visual | Internal | VisualTag | File | Line |")
    print("|---|---|---|---|---|---|---:|")
    for hit in entries[:shown]:
        print(
            f"| {md_cell(hit.match_type)} | {md_cell(hit.page)} | {md_cell(hit.visual)} | {md_cell(hit.visual_internal)} | {md_cell(hit.visual_tag)} | {md_cell(hit.file)} | {hit.line} |"
        )
    if shown < len(entries):
        print(f"\n_Omitted {len(entries) - shown} more rows. Use --max-items 0 to show all._")


def print_markdown_output(
    term: str,
    semantic_hits: dict[str, list[SemanticHit]],
    report_hits: list[ReportHit],
    max_items: int,
) -> None:
    term_id = f"term-{slugify(term)}"
    sec1_id = f"{term_id}-semantic-model-references"
    sec2_id = f"{term_id}-reports-page-visual"

    print(f"<a id=\"{term_id}\"></a>")
    print(f"## Term: {md_cell(term)}")
    print(
        f"Jump to: [1) Semantic Model References](#{sec1_id}) | [2) Reports - Page, Visual](#{sec2_id})"
    )

    print(f"\n<a id=\"{sec1_id}\"></a>")
    print("\n### 1) Semantic Model References - records, calc columns, measures")
    print("| Type | Count |")
    print("|---|---:|")
    print(f"| records | {len(semantic_hits['record'])} |")
    print(f"| calc columns | {len(semantic_hits['calc_column'])} |")
    print(f"| measures | {len(semantic_hits['measure'])} |")
    print(
        f"\nJump to: [Records](#{term_id}-records) | [Calc Columns](#{term_id}-calc-columns) | [Measures](#{term_id}-measures)"
    )

    for key, title in (
        ("record", "Records"),
        ("calc_column", "Calc Columns"),
        ("measure", "Measures"),
    ):
        entries = semantic_hits[key]
        shown = clamp_limit(max_items, len(entries))
        subsection_id = f"{term_id}-{slugify(title)}"
        print(f"\n<a id=\"{subsection_id}\"></a>")
        print(f"\n#### {title} ({len(entries)} total, showing {shown})")
        print_semantic_table(entries, max_items)

    print(f"\n<a id=\"{sec2_id}\"></a>")
    print("\n### 2) Reports - Page, Visual")
    print("| Metric | Value |")
    print("|---|---:|")
    print(f"| report reference hits | {len(report_hits)} |")

    report_match_counts: dict[str, int] = defaultdict(int)
    for hit in report_hits:
        for match_part in hit.match_type.split(","):
            report_match_counts[match_part] += 1
    for match_name in ("Entity", "Property", "queryRef"):
        print(f"| {match_name} hits | {report_match_counts.get(match_name, 0)} |")

    by_report: dict[str, list[ReportHit]] = defaultdict(list)
    for hit in report_hits:
        by_report[hit.report].append(hit)

    report_counts_id = f"{term_id}-report-counts"
    print(f"\nJump to: [Report Counts](#{report_counts_id})")

    report_links: list[str] = []
    for report_name in sorted(by_report.keys(), key=str.lower):
        report_id = f"{term_id}-report-{slugify(report_name)}"
        report_links.append(f"[{md_cell(report_name)}](#{report_id})")
    if report_links:
        print("Report sections: " + " | ".join(report_links))

    print(f"\n<a id=\"{report_counts_id}\"></a>")
    print("\n#### Report Counts")
    if by_report:
        print("| Report | Bindings |")
        print("|---|---:|")
        for report_name in sorted(by_report.keys(), key=str.lower):
            report_id = f"{term_id}-report-{slugify(report_name)}"
            report_link = f"[{md_cell(report_name)}](#{report_id})"
            print(f"| {report_link} | {len(by_report[report_name])} |")
    else:
        print("_No report matches._")

    for report_name in sorted(by_report.keys(), key=str.lower):
        items = by_report[report_name]
        shown = clamp_limit(max_items, len(items))
        report_id = f"{term_id}-report-{slugify(report_name)}"
        print(f"\n<a id=\"{report_id}\"></a>")
        print(f"\n#### Report: {md_cell(report_name)} ({len(items)} total, showing {shown})")
        print_report_table(items, max_items)


def emit_markdown(
    terms: list[str],
    semantic_by_term: dict[str, dict[str, list[SemanticHit]]],
    reports_by_term: dict[str, list[ReportHit]],
    max_items: int,
) -> None:
    print("# Power BI Reference Scan")
    for term in terms:
        print()
        print_markdown_output(
            term,
            semantic_by_term[term],
            reports_by_term[term],
            max_items,
        )


def build_json_output(
    terms: list[str],
    semantic_by_term: dict[str, dict[str, list[SemanticHit]]],
    reports_by_term: dict[str, list[ReportHit]],
) -> dict[str, Any]:
    out: dict[str, Any] = {"terms": {}}

    for term in terms:
        sem = semantic_by_term[term]
        rep = reports_by_term[term]
        out["terms"][term] = {
            "semantic_model_references": {
                "records": [asdict(x) for x in sem["record"]],
                "calc_columns": [asdict(x) for x in sem["calc_column"]],
                "measures": [asdict(x) for x in sem["measure"]],
                "counts": {
                    "records": len(sem["record"]),
                    "calc_columns": len(sem["calc_column"]),
                    "measures": len(sem["measure"]),
                },
            },
            "reports": {
                "page_visual_hits": [asdict(x) for x in rep],
                "count": len(rep),
            },
        }

    return out


def main() -> None:
    # On Windows, default console encodings (for example cp1252) can fail on
    # model/report text that contains Unicode characters. Force UTF-8 output so
    # piping to Out-File -Encoding utf8 works consistently.
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")

    args = parse_args()
    root = Path(args.root)

    if not root.exists() or not root.is_dir():
        raise FileNotFoundError(f"Root directory not found: {root}")

    semantic_by_term: dict[str, dict[str, list[SemanticHit]]] = {}
    reports_by_term: dict[str, list[ReportHit]] = {}

    for term in args.terms:
        semantic_by_term[term] = scan_semantic_models(root, term)
        reports_by_term[term] = scan_reports(root, term)

    if args.json:
        print(
            json.dumps(
                build_json_output(args.terms, semantic_by_term, reports_by_term),
                indent=2,
            )
        )
        return

    if args.output:
        output_path = Path(args.output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with output_path.open("w", encoding="utf-8", newline="\n") as output_file:
            with redirect_stdout(output_file):
                emit_markdown(args.terms, semantic_by_term, reports_by_term, args.max_items)
        return

    emit_markdown(args.terms, semantic_by_term, reports_by_term, args.max_items)


if __name__ == "__main__":
    main()
