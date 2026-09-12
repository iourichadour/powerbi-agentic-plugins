"""Unit tests for dax_test_helpers.py — port discovery, filtering, and result parsing.

Run with: uv run pytest plugins/powerbi/skills/dax-test-framework/tests -v
"""
import sys
import time
from pathlib import Path

import pytest

SCRIPTS_DIR = Path(__file__).resolve().parent.parent / "scripts"
sys.path.insert(0, str(SCRIPTS_DIR))

import dax_test_helpers as h  # noqa: E402


def test_discover_desktop_port_picks_newest(tmp_path):
    older = tmp_path / "12345"
    newer = tmp_path / "67890"
    older.mkdir()
    newer.mkdir()
    (older / "msmdsrv.port.txt").write_text("50001", encoding="utf-16")
    time.sleep(0.05)
    (newer / "msmdsrv.port.txt").write_text("50002", encoding="utf-16")

    port = h.discover_desktop_port(tmp_path)
    assert port == 50002


def test_discover_desktop_port_raises_when_missing(tmp_path):
    with pytest.raises(FileNotFoundError):
        h.discover_desktop_port(tmp_path)


def test_get_cloud_config_reports_only_missing_names():
    env = {"PBI_WORKSPACE": "ws", "PBI_MODEL": "model"}
    with pytest.raises(h.MissingCloudConfigError) as exc_info:
        h.get_cloud_config(env)
    assert set(exc_info.value.missing) == {"PBI_CLIENT_ID", "PBI_TENANT_ID", "PBI_CLIENT_SECRET"}


def test_get_cloud_config_succeeds_with_all_vars():
    env = {name: "x" for name in h.REQUIRED_CLOUD_ENV_VARS}
    config = h.get_cloud_config(env)
    assert config == env


def test_discover_test_files_excludes_scratch_queries(tmp_path):
    (tmp_path / "Query 1.dax").write_text("EVALUATE ROW(\"x\", 1)")
    (tmp_path / "Sales Measures.ANY.Tests.dax").write_text("EVALUATE ROW(\"x\", 1)")
    (tmp_path / "notes.txt").write_text("not a dax file")

    files = h.discover_test_files(tmp_path)
    assert [f.name for f in files] == ["Sales Measures.ANY.Tests.dax"]


def test_discover_test_files_name_filter(tmp_path):
    (tmp_path / "MeasureCertification.ANY.Business.Tests.dax").write_text("x")
    (tmp_path / "Sales Measures.ANY.Tests.dax").write_text("x")

    files = h.discover_test_files(tmp_path, name_filter="MeasureCertification.ANY.Business")
    assert [f.name for f in files] == ["MeasureCertification.ANY.Business.Tests.dax"]


def test_discover_test_files_environment_filter(tmp_path):
    (tmp_path / "Sales Measures.DEV.Tests.dax").write_text("x")
    (tmp_path / "Sales Measures.ANY.Tests.dax").write_text("x")

    dev_only = h.discover_test_files(tmp_path, environment="DEV")
    assert [f.name for f in dev_only] == ["Sales Measures.DEV.Tests.dax"]

    any_only = h.discover_test_files(tmp_path, environment="ANY")
    assert [f.name for f in any_only] == ["Sales Measures.ANY.Tests.dax"]


def test_available_environment_tokens(tmp_path):
    (tmp_path / "Sales Measures.DEV.Tests.dax").write_text("x")
    (tmp_path / "Sales Measures.PROD.Tests.dax").write_text("x")
    assert h.available_environment_tokens(tmp_path) == ["DEV", "PROD"]


@pytest.mark.parametrize("raw,expected", [
    (True, True),
    (False, False),
    ("TRUE", True),
    ("FALSE", False),
    ("", None),
    (None, None),
    ("garbage", None),
])
def test_normalize_passed(raw, expected):
    assert h.normalize_passed(raw) is expected


def test_normalize_blank_preserves_none_for_empty_string():
    assert h.normalize_blank("") is None
    assert h.normalize_blank(None) is None
    assert h.normalize_blank("value") == "value"
    assert h.normalize_blank(0) == 0


def test_rows_to_assertion_results_preserves_commas_and_scientific_notation():
    raw_rows = [
        {"TestName": "Big Number, With Comma", "Expected": "1.23E+10", "Actual": "1.23E+10", "Passed": "TRUE"},
    ]
    results = h.rows_to_assertion_results("File.dax", raw_rows)
    assert len(results) == 1
    r = results[0]
    assert r.test_name == "Big Number, With Comma"
    assert r.expected == "1.23E+10"
    assert r.actual == "1.23E+10"
    assert r.passed is True
    assert r.error_type is None


def test_rows_to_assertion_results_classifies_blank_as_error():
    raw_rows = [{"TestName": "T1", "Expected": "5", "Actual": "BLANK", "Passed": ""}]
    results = h.rows_to_assertion_results("File.dax", raw_rows)
    assert results[0].error_type == "BLANK_RESULT"
    assert results[0].passed is None


def test_rows_to_assertion_results_classifies_mismatch():
    raw_rows = [{"TestName": "T1", "Expected": "5", "Actual": "6", "Passed": "FALSE"}]
    results = h.rows_to_assertion_results("File.dax", raw_rows)
    assert results[0].error_type == "VALUE_MISMATCH"
    assert results[0].passed is False
