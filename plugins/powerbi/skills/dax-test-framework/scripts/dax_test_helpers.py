"""Shared helpers for the dax-test-framework skill: Desktop port discovery, CLOUD environment
config, typed DAX result-row parsing, and the fixed error-type vocabulary shared with
`dax-unit-testing`.

Used by both `run_dax_tests.py` (CLI) and the pytest wrapper so both entry points discover the
same `.dax` files and apply the same smoke-gate and assertion semantics. The ADOMD.NET transport
(`pythonnet`/`pyadomd`) is imported lazily inside `AdomdTransport.execute` so this module — and
everything except the real transport — can be unit tested without those dependencies installed.
"""
from __future__ import annotations

import dataclasses
import os
import re
import sys
from pathlib import Path
from typing import Protocol

# Fixed, machine-readable error-type vocabulary — shared with powerbi/dax-unit-testing.
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

REQUIRED_CLOUD_ENV_VARS = ("PBI_WORKSPACE", "PBI_MODEL", "PBI_CLIENT_ID", "PBI_TENANT_ID", "PBI_CLIENT_SECRET")

# PQL.Assert.* functions return a table (TestName/Expected/Actual/Passed columns) directly, so
# the smoke query must EVALUATE the call itself rather than try to index a scalar out of it.
SMOKE_QUERY = 'EVALUATE PQL.Assert.ShouldEqual("Smoke Test", 4, 2 + 2)'

_SCRATCH_FILE_RE = re.compile(r"^Query \d+$", re.IGNORECASE)
_TEST_FILE_RE = re.compile(r".*(Tests?)$", re.IGNORECASE)
_ENV_TOKENS = ("ANY", "DEV", "PROD")


class MissingCloudConfigError(Exception):
    def __init__(self, missing: list[str]):
        super().__init__(f"Missing required CLOUD environment variable(s): {', '.join(missing)}")
        self.missing = missing


class TransportConnectionError(Exception):
    """Raised by a Transport implementation on connection failure. Maps to CONNECTION_ERROR."""


class DaxQueryError(Exception):
    """Raised when a connected transport's query execution fails. Maps to DAX_ERROR."""


@dataclasses.dataclass
class AssertionResult:
    test_file: str
    test_name: str
    expected: str | None
    actual: str | None
    passed: bool | None  # None means blank/unrecognized -> BLANK_RESULT
    error_type: str | None = None
    error_message: str = ""


class Transport(Protocol):
    def execute(self, dax_query: str) -> list[dict]:
        ...


# --- DEV profile: dynamic Power BI Desktop port discovery -------------------------------

def discover_desktop_port(workspaces_root: Path) -> int:
    """Return the tabular engine port from the newest `msmdsrv.port.txt` under workspaces_root.

    Power BI Desktop writes one `<pid>/msmdsrv.port.txt` (UTF-16) per open instance under
    `%LOCALAPPDATA%\\Microsoft\\Power BI Desktop\\AnalysisServicesWorkspaces`. When multiple
    instances are open, the newest file (by modification time) is selected.
    """
    candidates = sorted(
        workspaces_root.rglob("msmdsrv.port.txt"),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )
    if not candidates:
        raise FileNotFoundError(f"No msmdsrv.port.txt found under {workspaces_root}")
    # Power BI Desktop writes this file as raw UTF-16LE, without a BOM, so it must be decoded
    # with the explicit little-endian codec rather than the BOM-sensing "utf-16" alias.
    text = candidates[0].read_text(encoding="utf-16-le").strip().lstrip("\ufeff")
    return int(text)


def default_desktop_workspaces_root() -> Path:
    local_app_data = os.environ.get("LOCALAPPDATA", "")
    return Path(local_app_data) / "Microsoft" / "Power BI Desktop" / "AnalysisServicesWorkspaces"


# --- CLOUD profile: environment-only credentials --------------------------------------------

def get_cloud_config(env: dict | None = None) -> dict[str, str]:
    env = env if env is not None else os.environ
    missing = [name for name in REQUIRED_CLOUD_ENV_VARS if not env.get(name)]
    if missing:
        raise MissingCloudConfigError(missing)
    return {name: env[name] for name in REQUIRED_CLOUD_ENV_VARS}


# --- Discovery and targeted execution ---------------------------------------------------------

def is_scratch_query_file(stem: str) -> bool:
    return bool(_SCRATCH_FILE_RE.match(stem))


def is_test_file(stem: str) -> bool:
    return bool(_TEST_FILE_RE.match(stem)) and not is_scratch_query_file(stem)


def parse_environment_token(stem: str) -> str:
    """Best-effort filename-environment token extraction; defaults to ANY when absent."""
    parts = stem.split(".")
    for part in parts:
        if part.upper() in _ENV_TOKENS:
            return part.upper()
    return "ANY"


def discover_test_files(root: Path, *, name_filter: str | None = None, environment: str | None = None) -> list[Path]:
    """Discover root-level *Tests.dax / *Test.dax files, excluding scratch queries.

    `name_filter` is an optional case-insensitive substring match against the filename.
    `environment` is an optional exact match against the filename's ANY/DEV/PROD token
    (independent of `name_filter`); omit to include files tagged with any token.
    """
    results = []
    for path in sorted(root.glob("*.dax")):
        stem = path.stem
        if not is_test_file(stem):
            continue
        if name_filter and name_filter.lower() not in stem.lower():
            continue
        if environment and parse_environment_token(stem) != environment.upper():
            continue
        results.append(path)
    return results


def available_environment_tokens(root: Path) -> list[str]:
    tokens = set()
    for path in sorted(root.glob("*.dax")):
        if is_test_file(path.stem):
            tokens.add(parse_environment_token(path.stem))
    return sorted(tokens)


# --- Typed result-row parsing --------------------------------------------------------------

_TRUE_TOKENS = {"true", "1", "yes"}
_FALSE_TOKENS = {"false", "0", "no"}


def normalize_passed(raw) -> bool | None:
    """Normalize a DAX `Passed` cell to True/False/None. None means blank/unrecognized."""
    if raw is None:
        return None
    if isinstance(raw, bool):
        return raw
    text = str(raw).strip()
    if text == "" or text.upper() == "BLANK":
        return None
    if text.lower() in _TRUE_TOKENS:
        return True
    if text.lower() in _FALSE_TOKENS:
        return False
    return None


def normalize_blank(value):
    """Preserve DAX BLANK() as a Python None rather than an empty string or NaN."""
    if value is None:
        return None
    if isinstance(value, str) and value == "":
        return None
    return value


def rows_to_assertion_results(test_file: str, raw_rows: list[dict]) -> list[AssertionResult]:
    """Convert raw typed rows (as returned by a Transport) into AssertionResult objects.

    Each raw row is expected to have TestName/Expected/Actual/Passed keys (case-insensitive).
    ADOMD.NET returns DAX-generated column names wrapped in brackets (e.g. `[TestName]`), so
    those are stripped before matching. This function performs no I/O and is fully unit-testable
    without a live model connection.
    """
    results = []
    for raw in raw_rows:
        lower = {k.strip("[]").lower(): v for k, v in raw.items()}
        test_name = str(lower.get("testname", "")).strip()
        expected = normalize_blank(lower.get("expected"))
        actual = normalize_blank(lower.get("actual"))
        passed = normalize_passed(lower.get("passed"))
        error_type = None
        message = ""
        if passed is None:
            error_type = "BLANK_RESULT"
            message = "Passed value was blank or unrecognized."
        elif passed is False:
            error_type = "VALUE_MISMATCH"
            message = f"Expected {expected!r}, got {actual!r}."
        results.append(AssertionResult(
            test_file=test_file, test_name=test_name, expected=expected, actual=actual,
            passed=passed, error_type=error_type, error_message=message,
        ))
    return results


# --- Real ADOMD.NET transport (lazy import) ----------------------------------------------------

_ADOMD_SEARCHED = False


def _ensure_adomd_on_sys_path() -> None:
    """Make `Microsoft.AnalysisServices.AdomdClient.dll` resolvable before `pyadomd` is imported.

    `pyadomd` calls `clr.AddReference("Microsoft.AnalysisServices.AdomdClient")` at import time;
    pythonnet resolves that reference by searching `sys.path`, not the OS `PATH`. Respect an
    explicit `ADOMD_DIR` override, then fall back to the well-known install locations (the
    on-machine ADOMD.NET client install and NuGet package caches) used previously by this repo's
    local test runner.
    """
    global _ADOMD_SEARCHED
    if _ADOMD_SEARCHED:
        return
    _ADOMD_SEARCHED = True

    candidates: list[Path] = []
    adomd_dir = os.environ.get("ADOMD_DIR", "")
    if adomd_dir:
        candidates.append(Path(adomd_dir))

    program_files_root = Path(os.environ.get("ProgramFiles", r"C:\Program Files")) / "Microsoft.NET" / "ADOMD.NET"
    if program_files_root.is_dir():
        candidates.extend(sorted(program_files_root.glob("*"), reverse=True))

    for nuget_root_env in ("LOCALAPPDATA", "USERPROFILE"):
        base = os.environ.get(nuget_root_env, "")
        if not base:
            continue
        nuget_pkg_dirs = [
            Path(base) / "NuGet" / "packages" / "microsoft.analysisservices.adomdclient",
            Path(base) / ".nuget" / "packages" / "microsoft.analysisservices.adomdclient",
        ]
        for pkg_dir in nuget_pkg_dirs:
            if pkg_dir.is_dir():
                candidates.extend(sorted(pkg_dir.glob("*/lib/net*"), reverse=True))

    for candidate in candidates:
        dll = candidate / "Microsoft.AnalysisServices.AdomdClient.dll"
        if dll.is_file():
            path_str = str(candidate)
            if path_str not in sys.path:
                sys.path.append(path_str)
            return


class AdomdTransport:
    """ADOMD.NET-backed transport for DEV (Desktop) and CLOUD (Fabric XMLA) profiles.

    pythonnet/pyadomd are imported lazily so this module can be imported (and everything else in
    it unit-tested) in environments without those Windows-only dependencies installed.
    """

    def __init__(self, connection_string: str):
        self.connection_string = connection_string

    def execute(self, dax_query: str) -> list[dict]:
        _ensure_adomd_on_sys_path()
        try:
            from pyadomd import Pyadomd  # type: ignore
        except ImportError as exc:  # pragma: no cover - exercised only without the dependency
            raise TransportConnectionError(f"pyadomd is not installed: {exc}") from exc

        try:
            conn_ctx = Pyadomd(self.connection_string)
            conn = conn_ctx.__enter__()
        except Exception as exc:  # noqa: BLE001 - any failure before a connection is open
            raise TransportConnectionError(str(exc)) from exc

        try:
            cur = conn.cursor()
            cur.execute(dax_query)
            columns = [d[0] for d in cur.description]
            return [dict(zip(columns, row)) for row in cur.fetchall()]
        except Exception as exc:  # noqa: BLE001 - a connected query that failed to execute
            raise DaxQueryError(str(exc)) from exc
        finally:
            conn_ctx.__exit__(None, None, None)


def build_dev_connection_string(port: int) -> str:
    return f"Provider=MSOLAP;Data Source=localhost:{port}"


def build_cloud_connection_string(config: dict[str, str]) -> str:
    workspace = config["PBI_WORKSPACE"]
    return (
        f"Provider=MSOLAP;Data Source=powerbi://api.powerbi.com/v1.0/myorg/{workspace};"
        f"Initial Catalog={config['PBI_MODEL']};"
        f"User ID=app:{config['PBI_CLIENT_ID']}@{config['PBI_TENANT_ID']};"
        f"Password={config['PBI_CLIENT_SECRET']};"
    )
