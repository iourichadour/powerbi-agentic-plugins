"""Pytest wrapper for PQL.Assert DAX Query View suites.

Uses the same discovery, smoke-gate, and result-parsing logic as run_dax_tests.py (via
dax_test_helpers.py), so both entry points apply identical semantics to the same .dax files.
See conftest.py for the --dax-* CLI options this wrapper reads.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import dax_test_helpers  # noqa: E402


def test_dax_assertions(dax_transport, dax_test_file):
    if dax_test_file is None:
        return  # skipped via conftest.py's pytest.mark.skip parametrization
    query = dax_test_file.read_text(encoding="utf-8-sig")
    raw = dax_transport.execute(query)
    results = dax_test_helpers.rows_to_assertion_results(dax_test_file.name, raw)
    failed = [r for r in results if r.passed is not True]
    assert not failed, "; ".join(
        f"{r.test_name}: {r.error_type} (expected={r.expected!r}, actual={r.actual!r})" for r in failed
    )
