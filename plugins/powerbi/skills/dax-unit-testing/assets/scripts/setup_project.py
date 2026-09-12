#!/usr/bin/env python3
"""One-time, idempotent scaffolding for a target semantic model project.

Usage:
    uv run setup_project.py --project-dir <path to *.SemanticModel project> [--json]

Deploys the PQL.Assert assertion functions into `<project-dir>/definition/functions.tmdl` and
copies `MeasureCertification.template.csv` to `<project-dir>/Certification/MeasureCertification.csv`
and `TESTING.template.md` to `<project-dir>/TESTING.md`.

Idempotent: creates each destination file only if it does not already exist, and NEVER overwrites
an existing file. Touches no other file or semantic model object. Kept separate from
`certify_measures.py` because it is the only script in this skill permitted to write the model's
assertion-library definition file — see design.md's "Decisions" section for the rationale.
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parent.parent.parent  # .../skills/dax-unit-testing
FUNCTIONS_SOURCE = SKILL_ROOT / "references" / "functions.tmdl"
REGISTRY_TEMPLATE_SOURCE = SKILL_ROOT / "assets" / "templates" / "MeasureCertification.template.csv"
TESTING_TEMPLATE_SOURCE = SKILL_ROOT / "assets" / "templates" / "TESTING.template.md"


def _scaffold_one(source: Path, dest: Path) -> dict:
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists():
        return {"destination": str(dest), "created": False, "alreadyExisted": True}
    shutil.copyfile(source, dest)
    return {"destination": str(dest), "created": True, "alreadyExisted": False}


def setup_project(project_dir: Path) -> list[dict]:
    functions_dest = project_dir / "definition" / "functions.tmdl"
    registry_dest = project_dir / "Certification" / "MeasureCertification.csv"
    testing_dest = project_dir / "TESTING.md"

    return [
        _scaffold_one(FUNCTIONS_SOURCE, functions_dest),
        _scaffold_one(REGISTRY_TEMPLATE_SOURCE, registry_dest),
        _scaffold_one(TESTING_TEMPLATE_SOURCE, testing_dest),
    ]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--project-dir", type=Path, required=True, help="Target *.SemanticModel project root")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)

    args.project_dir.mkdir(parents=True, exist_ok=True)
    results = setup_project(args.project_dir)

    if args.json:
        print(json.dumps({"projectDir": str(args.project_dir), "results": results}, indent=2))
    else:
        for r in results:
            status = "already existed (left unmodified)" if r["alreadyExisted"] else "created"
            print(f"{r['destination']}: {status}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
