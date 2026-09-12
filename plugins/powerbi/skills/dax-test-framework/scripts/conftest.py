"""pytest configuration for the DAX Query View test wrapper (test_dax_suite.py).

CLI options:
    --dax-profile {DEV,CLOUD}   (default: DEV)
    --dax-model-dir PATH        Semantic model project's DAXQueries/ folder (required to run)
    --dax-environment {ANY,DEV,PROD}
    --dax-file SUBSTRING        Case-insensitive filename substring filter

Example:
    uv run pytest dax-test-framework/scripts/test_dax_suite.py --dax-profile DEV \
        --dax-model-dir "C:/MyProject/MyModel.SemanticModel/DAXQueries"
"""
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent))
import dax_test_helpers  # noqa: E402
import run_dax_tests  # noqa: E402


def pytest_addoption(parser):
    group = parser.getgroup("dax-test-framework")
    group.addoption("--dax-profile", default="DEV", choices=["DEV", "CLOUD"])
    group.addoption("--dax-model-dir", default=None)
    group.addoption("--dax-environment", default=None, choices=[None, "ANY", "DEV", "PROD"])
    group.addoption("--dax-file", default=None)


@pytest.fixture(scope="session")
def dax_transport(request):
    profile = request.config.getoption("--dax-profile")
    transport = run_dax_tests.build_transport(profile)
    failure = run_dax_tests.run_smoke_gate(transport)
    if failure is not None:
        pytest.fail(f"Smoke gate failed [{failure.error_type}]: {failure.error_message}", pytrace=False)
    return transport


def pytest_generate_tests(metafunc):
    if "dax_test_file" not in metafunc.fixturenames:
        return
    model_dir_opt = metafunc.config.getoption("--dax-model-dir")
    if not model_dir_opt:
        metafunc.parametrize(
            "dax_test_file",
            [pytest.param(None, marks=pytest.mark.skip(reason="--dax-model-dir was not supplied"))],
        )
        return
    files = dax_test_helpers.discover_test_files(
        Path(model_dir_opt),
        name_filter=metafunc.config.getoption("--dax-file"),
        environment=metafunc.config.getoption("--dax-environment"),
    )
    if not files:
        metafunc.parametrize(
            "dax_test_file",
            [pytest.param(None, marks=pytest.mark.skip(reason="no matching .dax test files were discovered"))],
        )
        return
    metafunc.parametrize("dax_test_file", files, ids=[f.name for f in files])
