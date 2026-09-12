"""Unit tests for run_dax_tests.py's smoke-gate and suite-execution logic, using a FakeTransport
so no live Power BI Desktop or Fabric connection is required.
"""
import sys
from pathlib import Path

import pytest

SCRIPTS_DIR = Path(__file__).resolve().parent.parent / "scripts"
sys.path.insert(0, str(SCRIPTS_DIR))

import dax_test_helpers as h  # noqa: E402
import run_dax_tests as r  # noqa: E402


class FakeTransport:
    """A Transport whose behavior is scripted per-query for deterministic tests."""

    def __init__(self, responses: dict[str, object]):
        # responses maps a query substring -> list[dict] rows, or an Exception instance to raise
        self.responses = responses
        self.calls: list[str] = []

    def execute(self, dax_query: str) -> list[dict]:
        self.calls.append(dax_query)
        for key, value in self.responses.items():
            if key in dax_query:
                if isinstance(value, Exception):
                    raise value
                return value
        raise AssertionError(f"No fake response configured for query: {dax_query!r}")


SMOKE_PASS_ROWS = [{"TestName": "Smoke Test", "Expected": "TRUE", "Actual": "TRUE", "Passed": "TRUE"}]
SMOKE_FAIL_ROWS = [{"TestName": "Smoke Test", "Expected": "TRUE", "Actual": "FALSE", "Passed": "FALSE"}]


def test_smoke_gate_passes():
    transport = FakeTransport({h.SMOKE_QUERY: SMOKE_PASS_ROWS})
    assert r.run_smoke_gate(transport) is None


def test_smoke_gate_fails_on_connection_error():
    transport = FakeTransport({h.SMOKE_QUERY: h.TransportConnectionError("no route to host")})
    failure = r.run_smoke_gate(transport)
    assert failure is not None
    assert failure.error_type == "CONNECTION_ERROR"


def test_smoke_gate_fails_when_library_missing():
    transport = FakeTransport({h.SMOKE_QUERY: h.DaxQueryError("Function 'PQL.Assert.ShouldBeTrue' not found")})
    failure = r.run_smoke_gate(transport)
    assert failure is not None
    assert failure.error_type == "DAX_ERROR"
    assert "PQL.Assert" in failure.error_message


def test_smoke_gate_fails_when_assertion_does_not_pass():
    transport = FakeTransport({h.SMOKE_QUERY: SMOKE_FAIL_ROWS})
    failure = r.run_smoke_gate(transport)
    assert failure is not None
    assert failure.passed is False


def test_run_suite_reports_value_mismatch_and_connection_error(tmp_path):
    file_ok = tmp_path / "Sales.ANY.Tests.dax"
    file_ok.write_text("EVALUATE ROW(1)", encoding="utf-8")
    file_fail = tmp_path / "Margin.ANY.Tests.dax"
    file_fail.write_text("EVALUATE ROW(2)", encoding="utf-8")

    transport = FakeTransport({
        "ROW(1)": [{"TestName": "Sales Test", "Expected": "100", "Actual": "100", "Passed": "TRUE"}],
        "ROW(2)": h.DaxQueryError("column not found"),
    })

    results = r.run_suite(transport, [file_ok, file_fail])
    assert len(results) == 2
    ok_result = next(x for x in results if x.test_file == "Sales.ANY.Tests.dax")
    fail_result = next(x for x in results if x.test_file == "Margin.ANY.Tests.dax")
    assert ok_result.passed is True
    assert fail_result.error_type == "DAX_ERROR"


def test_write_junit_and_markdown_reports(tmp_path):
    results = [
        h.AssertionResult(test_file="A.dax", test_name="T1", expected="1", actual="1", passed=True),
        h.AssertionResult(test_file="B.dax", test_name="T2", expected="1", actual="2", passed=False,
                           error_type="VALUE_MISMATCH", error_message="mismatch"),
    ]
    junit_path = tmp_path / "junit.xml"
    md_path = tmp_path / "failures.md"
    r.write_junit(junit_path, results)
    r.write_markdown(md_path, results)

    junit_text = junit_path.read_text(encoding="utf-8")
    assert 'tests="2"' in junit_text
    assert 'failures="1"' in junit_text
    assert "VALUE_MISMATCH" in junit_text

    md_text = md_path.read_text(encoding="utf-8")
    assert "1 failure(s)" in md_text
    assert "B.dax" in md_text
