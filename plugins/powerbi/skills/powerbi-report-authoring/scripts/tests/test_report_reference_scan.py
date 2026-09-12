from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPTS_DIR = Path(__file__).resolve().parents[1]
SCANNER = SCRIPTS_DIR / "report_reference_scan.py"
WRAPPER = SCRIPTS_DIR / "report_reference_scan.ps1"


class ReportReferenceScanTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        model_definition = self.root / "Demo.SemanticModel" / "definition"
        tables = model_definition / "tables"
        visual = self.root / "Demo.Report" / "definition" / "pages" / "page1" / "visuals" / "visual1"
        tables.mkdir(parents=True)
        visual.mkdir(parents=True)

        (tables / "Sales.tmdl").write_text(
            "table Sales\n"
            "\tcolumn Amount\n"
            "\tmeasure 'Total Sales' = SUM('Sales'[Amount])\n"
            "\tcolumn 'Adjusted Amount' = 'Sales'[Amount]\n",
            encoding="utf-8",
        )
        (model_definition / "relationships.tmdl").write_text(
            "relationship SalesToDate\n\tfromColumn: Sales.Amount\n",
            encoding="utf-8",
        )
        (visual.parent.parent / "page.json").write_text(
            json.dumps({"name": "page1", "displayName": "Overview"}, indent=2),
            encoding="utf-8",
        )
        (visual / "visual.json").write_text(
            json.dumps(
                {
                    "name": "RevenueVisualTag",
                    "displayName": "Revenue Visual",
                    "visual": {
                        "query": {
                            "queryState": {
                                "Values": {
                                    "projections": [
                                        {
                                            "queryRef": "Sales.Total Sales",
                                            "field": {
                                                "Measure": {
                                                    "Expression": {"SourceRef": {"Entity": "Sales"}},
                                                    "Property": "Total Sales",
                                                }
                                            },
                                        },
                                        {
                                            "queryRef": "Sales.Amount",
                                            "field": {
                                                "Column": {
                                                    "Expression": {"SourceRef": {"Entity": "Sales"}},
                                                    "Property": "Amount",
                                                }
                                            },
                                        },
                                    ]
                                }
                            }
                        }
                    },
                },
                indent=2,
            ),
            encoding="utf-8",
        )

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def run_scanner(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCANNER), *arguments],
            capture_output=True,
            text=True,
            encoding="utf-8",
        )

    def run_wrapper(self, arguments: str) -> subprocess.CompletedProcess[str]:
        powershell = shutil.which("powershell") or shutil.which("pwsh")
        if not powershell:
            self.skipTest("PowerShell is not available")
        command = f"& '{WRAPPER}' -Root '{self.root}' {arguments}"
        return subprocess.run(
            [powershell, "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", command],
            capture_output=True,
            text=True,
            encoding="utf-8",
        )

    def test_json_finds_tmdl_and_pbir_context(self) -> None:
        result = self.run_scanner(
            "--root", str(self.root), "--terms", "Sales", "Amount", "Total Sales", "--json"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        data = json.loads(result.stdout)["terms"]

        sales_semantic = data["Sales"]["semantic_model_references"]
        outside_hits = [
            hit for hit in sales_semantic["records"] if hit["file"].endswith("relationships.tmdl")
        ]
        self.assertGreaterEqual(len(sales_semantic["records"]), 2)
        self.assertEqual(len(outside_hits), 1)
        self.assertTrue(all(hit["table"] == "" and hit["object_name"] == "" for hit in outside_hits))

        expected_match_types = {
            "Sales": {"Entity", "queryRef"},
            "Amount": {"Property", "queryRef"},
            "Total Sales": {"Property", "queryRef"},
        }
        for term, expected in expected_match_types.items():
            report_hits = data[term]["reports"]["page_visual_hits"]
            self.assertGreaterEqual(len(report_hits), 2)
            self.assertTrue(expected.issubset({hit["match_type"] for hit in report_hits}))
            self.assertTrue(all(hit["page"] == "Overview" for hit in report_hits))
            self.assertTrue(all(hit["visual"] == "Revenue Visual" for hit in report_hits))
            self.assertTrue(all(hit["file"].endswith("visual.json") for hit in report_hits))
            self.assertTrue(all(hit["line"] > 0 and hit["line_text"] for hit in report_hits))

    def test_markdown_multiple_terms_limit_and_output_file(self) -> None:
        result = self.run_scanner(
            "--root", str(self.root), "--terms", "Sales", "Amount", "--max-items", "1"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("# Power BI Reference Scan", result.stdout)
        self.assertIn("## Term: Sales", result.stdout)
        self.assertIn("## Term: Amount", result.stdout)
        self.assertIn("Omitted", result.stdout)

        output_path = self.root / "scan result.md"
        wrapped = self.run_wrapper(f"-Terms 'Sales','Amount' -Output '{output_path}' -MaxItems 1")
        self.assertEqual(wrapped.returncode, 0, wrapped.stderr)
        self.assertTrue(output_path.exists())
        self.assertIn("## Term: Sales", output_path.read_text(encoding="utf-8"))

    def test_cli_rejects_invalid_arguments_and_root(self) -> None:
        missing_terms = self.run_scanner("--root", str(self.root))
        self.assertNotEqual(missing_terms.returncode, 0)
        self.assertIn("--terms", missing_terms.stderr)

        incompatible = self.run_scanner(
            "--root", str(self.root), "--terms", "Sales", "--json", "--output", "scan.md"
        )
        self.assertNotEqual(incompatible.returncode, 0)
        self.assertIn("not allowed", incompatible.stderr)

        missing_root = self.run_scanner(
            "--root", str(self.root / "missing"), "--terms", "Sales"
        )
        self.assertNotEqual(missing_root.returncode, 0)
        self.assertIn("Root directory not found", missing_root.stderr)

    def test_wrapper_json_validation_and_exit_code(self) -> None:
        success = self.run_wrapper("-Terms 'Sales','Amount' -Json")
        self.assertEqual(success.returncode, 0, success.stderr)
        self.assertEqual(set(json.loads(success.stdout)["terms"]), {"Sales", "Amount"})

        incompatible = self.run_wrapper("-Terms 'Sales' -Json -Output 'scan.md'")
        self.assertNotEqual(incompatible.returncode, 0)
        self.assertIn("-Json and -Output cannot be used", incompatible.stderr)
        self.assertIn("together", incompatible.stderr)

        missing = self.run_wrapper("-Terms 'Sales'")
        missing_command = missing.args[-1].replace(str(self.root), str(self.root / "missing"), 1)
        powershell = missing.args[0]
        propagated = subprocess.run(
            [powershell, "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", missing_command],
            capture_output=True,
            text=True,
            encoding="utf-8",
        )
        self.assertNotEqual(propagated.returncode, 0)
        self.assertIn("Root directory not found", propagated.stderr)


if __name__ == "__main__":
    unittest.main()