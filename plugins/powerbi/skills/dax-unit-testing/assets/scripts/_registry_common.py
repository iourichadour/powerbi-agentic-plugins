"""Shared constants and helpers for the MeasureCertification.csv registry contract.

This module is imported by every `dax-unit-testing` automation script
(`validate_registry.py`, `generate_measure_tests.py`, `certify_measures.py`,
`coverage_report.py`, `setup_project.py`). It is not a standalone CLI.

See ../references/certification-registry-schema.md for the full column contract this
module implements, and ../references/legacy-registry-migration.md for the 11-column
legacy schema handled by `certify_measures.py --migrate-legacy`.
"""
from __future__ import annotations

import csv
import dataclasses
import datetime as _dt
import re
from pathlib import Path
from typing import Iterable

# --- Schema ------------------------------------------------------------------

COLUMNS: tuple[str, ...] = (
    "MeasureName",
    "TestName",
    "TestCategory",
    "FilterExpression",
    "ExpectedValue",
    "Tolerance",
    "Owner",
    "Status",
    "ApprovalSource",
    "ApprovedBy",
    "ApprovedOn",
    "Severity",
    "RequirementId",
    "LastReviewed",
)

LEGACY_COLUMNS: tuple[str, ...] = (
    "MeasureName",
    "TestName",
    "TestCategory",
    "FilterExpression",
    "ExpectedValue",
    "Tolerance",
    "Owner",
    "Status",
    "Severity",
    "RequirementId",
    "LastReviewed",
)

TEST_CATEGORIES = frozenset({"Structural", "Certification", "Aggregation", "Regression"})
NON_STRUCTURAL_CATEGORIES = TEST_CATEGORIES - {"Structural"}
STATUSES = frozenset({"Pending", "Approved", "Retired"})
APPROVAL_SOURCES = frozenset({"Structural", "Developer", "Business"})
SEVERITIES = frozenset({"Blocker", "Critical", "Major", "Minor", "Info"})

NOT_APPLICABLE = "N/A"
PENDING_PLACEHOLDER = "TBD"

# Fixed, machine-readable error-type vocabulary (powerbi/dax-unit-testing capability).
ERROR_TYPES = frozenset({
    "VALUE_MISMATCH",
    "BLANK_RESULT",
    "DAX_ERROR",
    "MEASURE_NOT_FOUND",
    "CERTIFICATION_PENDING",
    "METADATA_INCOMPLETE",
    "REGISTRY_INVALID",
    "GENERATED_FILE_MODIFIED",
    "CONNECTION_ERROR",
})

_ISO_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
_VALID_EXPECTED_VALUE_TOKENS = frozenset({"NOT_BLANK", ">=0", ">0"})
_NUMERIC_RE = re.compile(r"^-?\d+(\.\d+)?$")


@dataclasses.dataclass
class Finding:
    """A single validation/generation/scan finding using the fixed error vocabulary."""

    error_type: str
    message: str
    measure_name: str = ""
    test_name: str = ""
    row_number: int | None = None  # 1-based data row number (header excluded)

    def __post_init__(self) -> None:
        if self.error_type not in ERROR_TYPES:
            raise ValueError(f"Unknown error_type: {self.error_type!r}")

    def __str__(self) -> str:  # pragma: no cover - convenience only
        loc = f"{self.measure_name}/{self.test_name}" if self.measure_name else "<file>"
        row = f" (row {self.row_number})" if self.row_number is not None else ""
        return f"[{self.error_type}] {loc}{row}: {self.message}"


class RegistryError(Exception):
    """Raised when the registry cannot be processed at all (e.g. bad header)."""

    def __init__(self, finding: Finding):
        super().__init__(str(finding))
        self.finding = finding


# --- CSV I/O -------------------------------------------------------------------

def read_registry_rows(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    """Read a registry CSV, returning (header, rows). Raises RegistryError on a bad header."""
    with path.open("r", encoding="utf-8-sig", newline="") as fh:
        reader = csv.reader(fh)
        try:
            header = next(reader)
        except StopIteration:
            header = []
        rows = []
        for raw in reader:
            if not raw:
                continue
            rows.append(raw)

    if header != list(COLUMNS):
        raise RegistryError(Finding(
            error_type="REGISTRY_INVALID",
            message=(
                "Header does not match the required 14-column schema (name, order, and "
                f"count). Expected: {list(COLUMNS)}. Found: {header}."
            ),
        ))

    dict_rows: list[dict[str, str]] = []
    for i, raw in enumerate(rows, start=1):
        if len(raw) != len(COLUMNS):
            raise RegistryError(Finding(
                error_type="REGISTRY_INVALID",
                message=f"Row {i} has {len(raw)} fields; expected {len(COLUMNS)}.",
                row_number=i,
            ))
        dict_rows.append(dict(zip(COLUMNS, raw)))
    return list(COLUMNS), dict_rows


def write_registry_rows(path: Path, rows: Iterable[dict[str, str]]) -> None:
    """Write registry rows deterministically (LF line endings, fixed column order)."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.writer(fh, lineterminator="\n")
        writer.writerow(list(COLUMNS))
        for row in rows:
            writer.writerow([row.get(col, "") for col in COLUMNS])


def read_legacy_registry_rows(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    with path.open("r", encoding="utf-8-sig", newline="") as fh:
        reader = csv.reader(fh)
        try:
            header = next(reader)
        except StopIteration:
            header = []
        raw_rows = [r for r in reader if r]

    if header != list(LEGACY_COLUMNS):
        raise RegistryError(Finding(
            error_type="REGISTRY_INVALID",
            message=(
                "Legacy header does not match the required 11-column legacy schema. "
                f"Expected: {list(LEGACY_COLUMNS)}. Found: {header}."
            ),
        ))

    dict_rows = [dict(zip(LEGACY_COLUMNS, raw)) for raw in raw_rows]
    return list(LEGACY_COLUMNS), dict_rows


# --- Value validators ------------------------------------------------------------

def is_valid_iso_date_or_na(value: str, *, na_allowed: bool) -> bool:
    if na_allowed and value == NOT_APPLICABLE:
        return True
    if not _ISO_DATE_RE.match(value or ""):
        return False
    try:
        _dt.date.fromisoformat(value)
    except ValueError:
        return False
    return True


def is_valid_expected_value(value: str) -> bool:
    if value in _VALID_EXPECTED_VALUE_TOKENS:
        return True
    return bool(_NUMERIC_RE.match(value or ""))


def is_valid_tolerance(value: str) -> bool:
    if value == "":
        return True
    if not _NUMERIC_RE.match(value):
        return False
    return float(value) >= 0


# --- Model measure discovery (offline, TMDL-based) --------------------------------

_MEASURE_LINE_RE = re.compile(
    r"^\s*measure\s+(?:'(?P<quoted>[^']+)'|(?P<bare>[A-Za-z_][A-Za-z0-9_.]*))\s*="
)


def scan_model_measures(model_dir: Path) -> set[str]:
    """Discover measure names by scanning *.tmdl files under model_dir for `measure` declarations.

    This is a lightweight, offline scan used so registry-aware scripts can validate
    `MeasureName` existence without a live model connection. It is intentionally
    conservative: only lines matching TMDL's `measure 'Name' = ...` / `measure Name = ...`
    syntax are recognized.
    """
    measures: set[str] = set()
    if not model_dir.exists():
        return measures
    for tmdl_file in model_dir.rglob("*.tmdl"):
        try:
            text = tmdl_file.read_text(encoding="utf-8-sig")
        except (UnicodeDecodeError, OSError):
            continue
        for line in text.splitlines():
            m = _MEASURE_LINE_RE.match(line)
            if m:
                name = m.group("quoted") or m.group("bare")
                if name:
                    measures.add(name)
    return measures


def sanitize_filename_component(name: str) -> str:
    """Sanitize a measure/area name for use in a generated .dax filename."""
    cleaned = re.sub(r"[^A-Za-z0-9 _-]", "", name).strip()
    return cleaned or "Measure"


# --- Model measure metadata (offline, TMDL-based, used by certify_measures.py `scan`) ----------

@dataclasses.dataclass
class MeasureMetadata:
    name: str
    table: str = ""
    description: str = ""
    format_string: str = ""
    display_folder: str = ""

    @property
    def home_table(self) -> str:
        return self.table


_TABLE_LINE_RE = re.compile(r"^table\s+(?:'(?P<quoted>[^']+)'|(?P<bare>\S+))\s*$")
_DOC_COMMENT_RE = re.compile(r"^\s*///\s?(.*)$")
_FORMAT_STRING_RE = re.compile(r"^\s*formatString\s*:\s*(.+?)\s*$")
_DISPLAY_FOLDER_RE = re.compile(r"^\s*displayFolder\s*:\s*(.+?)\s*$")


def _indent_depth(line: str) -> int:
    return len(line) - len(line.lstrip("\t"))


def scan_model_measure_metadata(model_dir: Path) -> dict[str, MeasureMetadata]:
    """Parse *.tmdl files for measure declarations and their immediate metadata properties.

    Offline, best-effort TMDL scan: captures the enclosing `table`, any contiguous `///` doc
    comment immediately preceding the measure as its description, and `formatString`/
    `displayFolder` properties indented directly under the measure line.
    """
    result: dict[str, MeasureMetadata] = {}
    if not model_dir.exists():
        return result

    for tmdl_file in model_dir.rglob("*.tmdl"):
        try:
            lines = tmdl_file.read_text(encoding="utf-8-sig").splitlines()
        except (UnicodeDecodeError, OSError):
            continue

        current_table = ""
        pending_doc_lines: list[str] = []
        i = 0
        while i < len(lines):
            line = lines[i]
            table_match = _TABLE_LINE_RE.match(line.strip()) if _indent_depth(line) == 0 else None
            if table_match:
                current_table = table_match.group("quoted") or table_match.group("bare")
                pending_doc_lines = []
                i += 1
                continue

            doc_match = _DOC_COMMENT_RE.match(line)
            if doc_match:
                pending_doc_lines.append(doc_match.group(1))
                i += 1
                continue

            measure_match = _MEASURE_LINE_RE.match(line)
            if measure_match:
                name = measure_match.group("quoted") or measure_match.group("bare")
                measure_depth = _indent_depth(line)
                meta = MeasureMetadata(name=name, table=current_table, description=" ".join(pending_doc_lines).strip())
                pending_doc_lines = []
                j = i + 1
                while j < len(lines):
                    nxt = lines[j]
                    if nxt.strip() == "":
                        j += 1
                        continue
                    if _indent_depth(nxt) <= measure_depth:
                        break
                    fmt_match = _FORMAT_STRING_RE.match(nxt)
                    if fmt_match:
                        meta.format_string = fmt_match.group(1)
                    folder_match = _DISPLAY_FOLDER_RE.match(nxt)
                    if folder_match:
                        meta.display_folder = folder_match.group(1)
                    j += 1
                result[name] = meta
                i = j
                continue

            if line.strip() == "":
                pending_doc_lines = []
            i += 1

    return result
