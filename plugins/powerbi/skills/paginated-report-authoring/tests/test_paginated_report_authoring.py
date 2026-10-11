import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


SKILL_ROOT = Path(__file__).parents[1]
GENERATOR = SKILL_ROOT / "scripts" / "gen_rdl.py"
PUBLISHER = SKILL_ROOT / "scripts" / "publish.ps1"
RDL_NS = "http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition"


def generate(output: Path, request: Path | None = None) -> None:
    command = [
        sys.executable,
        str(GENERATOR),
        "--dataset-guid",
        "11111111-1111-1111-1111-111111111111",
        "--dataset-name",
        "DemoModel",
        "--workspace-name",
        "DemoWorkspace",
        "--display-name",
        "DemoReport",
        "--output",
        str(output),
    ]
    if request:
        command.extend(["--request-output", str(request)])
    subprocess.run(command, check=True, capture_output=True, text=True)


def test_generator_creates_reproducible_schema_valid_rdl(tmp_path):
    first = tmp_path / "first.rdl"
    second = tmp_path / "second.rdl"
    generate(first)
    generate(second)

    assert first.read_bytes() == second.read_bytes()
    root = ET.parse(first).getroot()
    assert root.tag == f"{{{RDL_NS}}}Report"
    assert root.attrib["MustUnderstand"] == "df"

    child_names = [child.tag.rsplit("}", 1)[-1] for child in root]
    assert child_names[:6] == ["ReportUnitType", "ReportID", "DefaultFontFamily", "AutoRefresh", "DataSources", "DataSets"]
    assert "[ClaimID]" in first.read_text(encoding="utf-8")
    assert first.read_text(encoding="utf-8").count("<ReportParameter ") == 5
    assert "<MultiValue>true</MultiValue>" in first.read_text(encoding="utf-8")
    assert len(re.findall(r'<DataSet Name="', first.read_text(encoding="utf-8"))) == 4
    assert "11111111-1111-1111-1111-111111111111" in first.read_text(encoding="utf-8")
    assert "accessToken" not in first.read_text(encoding="utf-8")


def test_generator_request_uses_output_filename_and_has_no_credentials(tmp_path):
    output = tmp_path / "demo.rdl"
    request = tmp_path / "request.json"
    generate(output, request)
    payload = request.read_text(encoding="utf-8")
    assert '"path": "demo.rdl"' in payload
    assert "password" not in payload.lower()
    assert "Bearer " not in payload


def test_publisher_requires_explicit_workspace_and_safe_overwrite():
    script = PUBLISHER.read_text(encoding="utf-8")
    assert "[Parameter(Mandatory = $true)]" in script
    assert "[string]$WorkspaceId" in script
    assert "[switch]$Overwrite" in script
    assert "$nameConflict = if ($Overwrite) { 'Overwrite' } else { 'Abort' }" in script
    assert "importState -eq 'Failed'" in script
    assert "did not reach a terminal state" in script
    assert "C:\\Users\\" not in script
    assert "Write-Output $token" not in script


def test_skill_and_agent_routing_boundaries():
    skill = (SKILL_ROOT / "SKILL.md").read_text(encoding="utf-8")
    agent = (SKILL_ROOT.parents[1] / "agents" / "powerbi-developer.agent.md").read_text(encoding="utf-8")
    assert "name: paginated-report-authoring" in skill
    assert "RDL" in skill and "InvalidDefinitionFormat" in skill
    assert "powerbi-report-authoring" in skill
    assert "paginated-report-authoring" in agent
    assert "PBIR/PBIP" in agent
