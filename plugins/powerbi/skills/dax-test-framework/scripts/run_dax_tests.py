#!/usr/bin/env python3
"""Standalone CLI runner for PQL.Assert DAX Query View test suites.

Usage:
    uv run run_dax_tests.py --profile DEV --model-dir <path to *.SemanticModel project> [--file <substring>] [--environment ANY|DEV|PROD] [--reports-dir reports]
    uv run run_dax_tests.py --profile CLOUD --model-dir <path> [...]

DEV connects to the newest running Power BI Desktop instance (dynamic port discovery). CLOUD
connects to a Fabric XMLA endpoint using PBI_WORKSPACE/PBI_MODEL/PBI_CLIENT_ID/PBI_TENANT_ID/
PBI_CLIENT_SECRET from the process environment — these are never printed or written to reports.

Runs a PQL.Assert smoke assertion before the suite; a missing/failing smoke gate stops the run
before any suite assertions are reported. Exit code is 0 only when every selected assertion
passed and no query/connection errors occurred.
"""
from __future__ import annotations

import argparse
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from dax_test_helpers import (  # noqa: E402
    AdomdTransport,
    AssertionResult,
    DaxQueryError,
    MissingCloudConfigError,
    Transport,
    TransportConnectionError,
    SMOKE_QUERY,
    available_environment_tokens,
    build_cloud_connection_string,
    build_dev_connection_string,
    default_desktop_workspaces_root,
    discover_desktop_port,
    discover_test_files,
    get_cloud_config,
    rows_to_assertion_results,
)


def run_smoke_gate(transport: Transport) -> AssertionResult | None:
    """Return None if the smoke gate passed, or the failing AssertionResult otherwise."""
    try:
        raw = transport.execute(SMOKE_QUERY)
    except TransportConnectionError as exc:
        return AssertionResult(
            test_file="<smoke>", test_name="Smoke Test", expected="TRUE", actual=None, passed=None,
            error_type="CONNECTION_ERROR", error_message=str(exc),
        )
    except DaxQueryError as exc:
        return AssertionResult(
            test_file="<smoke>", test_name="Smoke Test", expected="TRUE", actual=None, passed=None,
            error_type="DAX_ERROR",
            error_message=f"Smoke assertion query failed; is the PQL.Assert library deployed? ({exc})",
        )

    if not raw:
        return AssertionResult(
            test_file="<smoke>", test_name="Smoke Test", expected="TRUE", actual=None, passed=None,
            error_type="DAX_ERROR", error_message="Smoke query returned no rows.",
        )
    result = rows_to_assertion_results("<smoke>", raw)[0]
    if result.passed is not True:
        result.error_type = result.error_type or "DAX_ERROR"
        result.error_message = result.error_message or "Smoke assertion did not pass; verify PQL.Assert is deployed."
        return result
    return None


def run_suite(transport: Transport, test_files: list[Path]) -> list[AssertionResult]:
    all_results: list[AssertionResult] = []
    for path in test_files:
        query = path.read_text(encoding="utf-8-sig")
        try:
            raw = transport.execute(query)
        except TransportConnectionError as exc:
            all_results.append(AssertionResult(
                test_file=path.name, test_name="<file>", expected=None, actual=None, passed=None,
                error_type="CONNECTION_ERROR", error_message=str(exc),
            ))
            continue
        except DaxQueryError as exc:
            all_results.append(AssertionResult(
                test_file=path.name, test_name="<file>", expected=None, actual=None, passed=None,
                error_type="DAX_ERROR", error_message=str(exc),
            ))
            continue
        if not raw:
            all_results.append(AssertionResult(
                test_file=path.name, test_name="<file>", expected=None, actual=None, passed=None,
                error_type="BLANK_RESULT", error_message="Query returned no rows.",
            ))
            continue
        all_results.extend(rows_to_assertion_results(path.name, raw))
    return all_results


def build_transport(profile: str) -> Transport:
    if profile == "DEV":
        port = discover_desktop_port(default_desktop_workspaces_root())
        return AdomdTransport(build_dev_connection_string(port))
    if profile == "CLOUD":
        config = get_cloud_config()
        return AdomdTransport(build_cloud_connection_string(config))
    raise ValueError(f"Unknown profile: {profile}")


def write_junit(path: Path, results: list[AssertionResult]) -> None:
    testsuite = ET.Element("testsuite", name="dax-test-framework", tests=str(len(results)))
    failures = 0
    for r in results:
        testcase = ET.SubElement(testsuite, "testcase", classname=r.test_file, name=r.test_name)
        if r.passed is not True:
            failures += 1
            failure = ET.SubElement(testcase, "failure", message=r.error_message or "assertion failed")
            failure.set("type", r.error_type or "VALUE_MISMATCH")
            failure.text = f"Expected: {r.expected!r}\nActual: {r.actual!r}"
    testsuite.set("failures", str(failures))
    path.parent.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(testsuite).write(path, encoding="utf-8", xml_declaration=True)


def write_markdown(path: Path, results: list[AssertionResult]) -> None:
    failed = [r for r in results if r.passed is not True]
    lines = [f"# DAX Test Run — {len(results)} assertion(s), {len(failed)} failure(s)", ""]
    if failed:
        lines += ["| Test File | Test Name | Error Type | Expected | Actual | Message |", "|---|---|---|---|---|---|"]
        for r in failed:
            lines.append(f"| {r.test_file} | {r.test_name} | {r.error_type} | {r.expected} | {r.actual} | {r.error_message} |")
    else:
        lines.append("All assertions passed.")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


def main(argv: list[str] | None = None) -> int:
    # Windows consoles often default stdout/stderr to a legacy codepage (e.g. cp1252) that can't
    # encode characters like "→" that appear in measure/test names; force UTF-8 with a safe
    # fallback so a printable failure never crashes the run after reports have already been written.
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8", errors="replace")

    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--profile", choices=["DEV", "CLOUD"], required=True)
    parser.add_argument("--model-dir", type=Path, required=True, help="Semantic model project's DAXQueries/ folder")
    parser.add_argument("--file", default=None, help="Case-insensitive filename substring filter")
    parser.add_argument("--environment", choices=["ANY", "DEV", "PROD"], default=None)
    parser.add_argument("--reports-dir", type=Path, default=Path("reports"))
    args = parser.parse_args(argv)

    test_files = discover_test_files(args.model_dir, name_filter=args.file, environment=args.environment)
    if not test_files:
        tokens = available_environment_tokens(args.model_dir)
        print(f"No test files matched. Available environment tokens: {tokens}", file=sys.stderr)
        return 1

    try:
        transport = build_transport(args.profile)
    except MissingCloudConfigError as exc:
        print(f"CONNECTION_ERROR: {exc}", file=sys.stderr)
        return 1
    except FileNotFoundError as exc:
        print(f"CONNECTION_ERROR: {exc}", file=sys.stderr)
        return 1

    smoke_failure = run_smoke_gate(transport)
    if smoke_failure is not None:
        print(f"SMOKE GATE FAILED [{smoke_failure.error_type}]: {smoke_failure.error_message}", file=sys.stderr)
        write_junit(args.reports_dir / "junit.xml", [smoke_failure])
        write_markdown(args.reports_dir / "failures.md", [smoke_failure])
        return 1

    results = run_suite(transport, test_files)
    write_junit(args.reports_dir / "junit.xml", results)
    write_markdown(args.reports_dir / "failures.md", results)

    failed = [r for r in results if r.passed is not True]
    print(f"Ran {len(results)} assertion(s) across {len(test_files)} file(s); {len(failed)} failure(s).")
    for r in failed:
        print(f"  [{r.error_type}] {r.test_file} :: {r.test_name} - {r.error_message}")

    return 0 if not failed else 1


if __name__ == "__main__":
    raise SystemExit(main())
