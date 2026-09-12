"""Fixture-based tests for the dax-unit-testing automation scripts.

Run with: uv run pytest plugins/powerbi/skills/dax-unit-testing/tests -v
"""
import json
import shutil
import sys
from pathlib import Path

import pytest

SCRIPTS_DIR = Path(__file__).resolve().parent.parent / "assets" / "scripts"
FIXTURES_DIR = Path(__file__).resolve().parent / "fixtures"
sys.path.insert(0, str(SCRIPTS_DIR))

import validate_registry as vr  # noqa: E402
import generate_measure_tests as gmt  # noqa: E402
import certify_measures as cm  # noqa: E402
import coverage_report as cr  # noqa: E402
import setup_project as sp  # noqa: E402
from _registry_common import RegistryError, read_registry_rows  # noqa: E402


# --- validate_registry.py ------------------------------------------------------------------

def test_valid_registry_has_no_findings_schema_only():
    findings, notes = vr.validate_registry(FIXTURES_DIR / "valid_registry.csv", None, schema_only=True)
    assert findings == []
    assert "not evaluated" in notes[0]


def test_malformed_registry_reports_expected_findings():
    findings, _ = vr.validate_registry(FIXTURES_DIR / "malformed_registry.csv", None, schema_only=True)
    error_types = {f.error_type for f in findings}
    assert error_types == {"REGISTRY_INVALID"}
    assert len(findings) == 5


def test_quoted_comma_filter_expression_parses_cleanly():
    findings, _ = vr.validate_registry(FIXTURES_DIR / "quoted_comma_registry.csv", None, schema_only=True)
    assert findings == []


def test_model_dir_flags_missing_measure():
    findings, _ = vr.validate_registry(FIXTURES_DIR / "unknown_measure_registry.csv", FIXTURES_DIR / "fixture_model", schema_only=False)
    assert len(findings) == 1
    assert findings[0].error_type == "REGISTRY_INVALID"
    assert "not found in the semantic model" in findings[0].message


def test_template_csv_passes_schema_only_validation():
    template = Path(__file__).resolve().parent.parent / "assets" / "templates" / "MeasureCertification.template.csv"
    findings, _ = vr.validate_registry(template, None, schema_only=True)
    assert findings == []


# --- generate_measure_tests.py --------------------------------------------------------------

def test_generation_is_idempotent_and_updates_dax_queries_json(tmp_path):
    written1, findings1 = gmt.generate(FIXTURES_DIR / "valid_registry.csv", tmp_path)
    assert written1 == ["Total Sales.ANY.Tests.dax"]
    assert findings1 == []
    gmt.update_dax_queries_json(tmp_path / "daxQueries.json", written1)

    content1 = (tmp_path / "Total Sales.ANY.Tests.dax").read_bytes()
    json1 = (tmp_path / "daxQueries.json").read_bytes()

    written2, findings2 = gmt.generate(FIXTURES_DIR / "valid_registry.csv", tmp_path)
    gmt.update_dax_queries_json(tmp_path / "daxQueries.json", written2)
    content2 = (tmp_path / "Total Sales.ANY.Tests.dax").read_bytes()
    json2 = (tmp_path / "daxQueries.json").read_bytes()

    assert content1 == content2
    assert json1 == json2


def test_generation_refuses_to_overwrite_hand_edited_file(tmp_path):
    written, _ = gmt.generate(FIXTURES_DIR / "valid_registry.csv", tmp_path)
    target = tmp_path / written[0]
    with target.open("a", encoding="utf-8") as fh:
        fh.write("\n// hand edit\n")

    written2, findings2 = gmt.generate(FIXTURES_DIR / "valid_registry.csv", tmp_path)
    assert written2 == []
    assert any(f.error_type == "GENERATED_FILE_MODIFIED" for f in findings2)


def test_generation_reports_pending_rows_as_certification_pending(tmp_path):
    registry = tmp_path / "reg.csv"
    registry.write_text(
        "MeasureName,TestName,TestCategory,FilterExpression,ExpectedValue,Tolerance,Owner,Status,ApprovalSource,ApprovedBy,ApprovedOn,Severity,RequirementId,LastReviewed\n"
        "X,X Cert,Certification,,TBD,0,TBD,Pending,,,,Major,TBD,2025-01-01\n",
        encoding="utf-8",
    )
    written, findings = gmt.generate(registry, tmp_path / "out")
    assert written == []
    assert any(f.error_type == "CERTIFICATION_PENDING" for f in findings)


def test_dax_queries_json_preserves_existing_entries(tmp_path):
    dax_json = tmp_path / "daxQueries.json"
    dax_json.write_text(json.dumps({"version": "1.0", "queries": [{"queryFile": "Hand.dax", "queryId": "abc"}]}), encoding="utf-8")
    gmt.update_dax_queries_json(dax_json, ["Generated.dax"])
    data = json.loads(dax_json.read_text(encoding="utf-8"))
    files = {q["queryFile"] for q in data["queries"]}
    assert files == {"Hand.dax", "Generated.dax"}


# --- certify_measures.py -------------------------------------------------------------------

def test_scan_reports_metadata_incomplete(tmp_path):
    registry_file = tmp_path / "reg.csv"
    shutil.copyfile(FIXTURES_DIR / "valid_registry.csv", registry_file)

    import contextlib
    import io
    buf = io.StringIO()

    class Args:
        model_dir = FIXTURES_DIR / "fixture_model"
        registry = registry_file
        json = True

    with contextlib.redirect_stdout(buf):
        cm.cmd_scan(Args())
    result = json.loads(buf.getvalue())
    assert any(f["error_type"] == "METADATA_INCOMPLETE" for f in result["findings"])


def test_sync_adds_rows_and_flags_orphans(tmp_path):
    registry = tmp_path / "reg.csv"
    registry.write_text(
        "MeasureName,TestName,TestCategory,FilterExpression,ExpectedValue,Tolerance,Owner,Status,ApprovalSource,ApprovedBy,ApprovedOn,Severity,RequirementId,LastReviewed\n"
        "Gone Measure,Gone Measure Structural Test,Structural,,NOT_BLANK,0,N/A,Approved,Structural,N/A,N/A,Major,,2025-01-01\n",
        encoding="utf-8",
    )

    class Args:
        def __init__(self):
            self.model_dir = FIXTURES_DIR / "fixture_model"
            self.registry = registry
            self.as_of_date = "2025-06-01"
            self.json = True

    import contextlib
    import io
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        cm.cmd_sync(Args())
    result = json.loads(buf.getvalue())
    assert len(result["addedRows"]) > 0
    assert any(r["measureName"] == "Gone Measure" for r in result["orphanedRows"])

    _, rows = read_registry_rows(registry)
    # orphaned row must still be present (never auto-deleted)
    assert any(r["MeasureName"] == "Gone Measure" for r in rows)


def test_certify_records_developer_baseline(tmp_path):
    registry = tmp_path / "reg.csv"
    shutil.copyfile(FIXTURES_DIR / "coverage_registry.csv", registry)

    class Args:
        def __init__(self):
            self.registry = registry
            self.measure = "Business Certified Measure"
            self.test_name = "Business Certified Measure Pending"
            self.expected_value = "77"
            self.filter_expression = "Sales[Amount] > 50"
            self.owner = "dev@example.com"
            self.tolerance = 5.0
            self.approval_source = "Developer"
            self.approved_by = "dev@example.com"
            self.approved_on = "2025-04-01"

    cm.cmd_certify(Args())
    _, rows = read_registry_rows(registry)
    row = next(r for r in rows if r["TestName"] == "Business Certified Measure Pending")
    assert row["Status"] == "Approved"
    assert row["ApprovalSource"] == "Developer"
    assert row["ExpectedValue"] == "77"


def test_certify_rejects_structural_approval_source(tmp_path):
    registry = tmp_path / "reg.csv"
    shutil.copyfile(FIXTURES_DIR / "coverage_registry.csv", registry)

    class Args:
        def __init__(self):
            self.registry = registry
            self.measure = "Business Certified Measure"
            self.test_name = "Business Certified Measure Pending"
            self.expected_value = "77"
            self.filter_expression = None
            self.owner = "x"
            self.tolerance = None
            self.approval_source = "Structural"
            self.approved_by = "x"
            self.approved_on = None

    assert cm.cmd_certify(Args()) == 2


def test_migrate_legacy_blocks_ambiguous_rows(tmp_path):
    class Args:
        def __init__(self):
            self.legacy_registry = FIXTURES_DIR / "legacy_registry.csv"
            self.output = tmp_path / "out.csv"
            self.mapping = None

    assert cm.cmd_migrate_legacy(Args()) == 1
    assert not (tmp_path / "out.csv").exists()


def test_migrate_legacy_succeeds_with_explicit_mapping(tmp_path):
    mapping_path = tmp_path / "mapping.json"
    mapping_path.write_text(json.dumps({
        "Total Sales::Total Sales West Region": {
            "approvalSource": "Business", "approvedBy": "finance@example.com", "approvedOn": "2025-01-15",
        }
    }), encoding="utf-8")

    class Args:
        def __init__(self):
            self.legacy_registry = FIXTURES_DIR / "legacy_registry.csv"
            self.output = tmp_path / "out.csv"
            self.mapping = mapping_path

    assert cm.cmd_migrate_legacy(Args()) == 0
    _, rows = read_registry_rows(tmp_path / "out.csv")
    structural = next(r for r in rows if r["TestCategory"] == "Structural")
    assert structural["ApprovalSource"] == "Structural" and structural["ApprovedBy"] == "N/A"
    business = next(r for r in rows if r["TestName"] == "Total Sales West Region")
    assert business["ApprovalSource"] == "Business"


# --- coverage_report.py --------------------------------------------------------------------

def test_coverage_report_computes_expected_percentages(tmp_path):
    coverage = cr.compute_coverage(FIXTURES_DIR / "fixture_model", FIXTURES_DIR / "coverage_registry.csv")
    assert coverage["totalMeasures"] == 4
    assert coverage["untestedMeasures"] == ["Untested Measure"]
    assert coverage["anyCoveragePct"] == 75.0


def test_coverage_report_is_read_only(tmp_path):
    registry = tmp_path / "reg.csv"
    shutil.copyfile(FIXTURES_DIR / "coverage_registry.csv", registry)
    before = registry.read_bytes()
    cr.compute_coverage(FIXTURES_DIR / "fixture_model", registry)
    after = registry.read_bytes()
    assert before == after


# --- setup_project.py ----------------------------------------------------------------------

def test_setup_project_creates_all_then_is_idempotent(tmp_path):
    project_dir = tmp_path / "Contoso.SemanticModel"
    results1 = sp.setup_project(project_dir)
    assert all(r["created"] for r in results1)

    hash_before = (project_dir / "TESTING.md").read_bytes()
    results2 = sp.setup_project(project_dir)
    assert all(r["alreadyExisted"] for r in results2)
    hash_after = (project_dir / "TESTING.md").read_bytes()
    assert hash_before == hash_after


def test_setup_project_completes_partial_setup(tmp_path):
    project_dir = tmp_path / "Contoso.SemanticModel"
    sp.setup_project(project_dir)
    (project_dir / "TESTING.md").unlink()

    results = sp.setup_project(project_dir)
    testing_result = next(r for r in results if r["destination"].endswith("TESTING.md"))
    assert testing_result["created"] is True
    other_results = [r for r in results if not r["destination"].endswith("TESTING.md")]
    assert all(r["alreadyExisted"] for r in other_results)
