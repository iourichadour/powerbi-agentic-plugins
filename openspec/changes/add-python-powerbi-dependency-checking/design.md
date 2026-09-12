## Context

See [proposal.md](proposal.md) for motivation and [the dependency-checking specification](specs/powerbi/dependency-checking/spec.md) for the behavior contract. The repository already includes a Python report-text scanner behind [report_reference_scan.ps1](../../../plugins/powerbi/skills/powerbi-report-authoring/scripts/report_reference_scan.ps1), but it searches caller-provided terms rather than constructing a complete cross-model dependency graph. `semantic-model-authoring` describes a manual local PBIP reference scan before rename/removal; the new capability becomes the shared, more complete check at that point.

ripbi demonstrates that offline static analysis of TMDL plus PBIR can expose reachability and unused objects quickly. It is a Rust binary; this design delivers an independent Python implementation suitable for the plugin's distributable skill assets.

## Goals / Non-Goals

**Goals:**
- Build one reusable read-only scanner, not copies embedded in architecture, model-authoring, report-authoring, or test skills.
- Analyze local PBIP source offline and produce traceable impact and unused-object results suitable for a developer and CI.
- Keep graph object identities stable so JSON results can be compared across runs and consumed by later coverage/governance tooling.

**Non-Goals:**
- Parse `.pbix`/`.pbit` binaries, query live Desktop/Fabric models, or scan a tenant.
- Modify, prune, rename, or remediate discovered objects.
- Claim runtime DAX semantics: dynamic references, external tools, and unsupported PBIR/TMDL constructs are reported as limitations, not silently inferred.
- Replace the existing term-oriented `report_reference_scan.py`; callers needing targeted raw-text evidence can continue to use it.

## Decisions

**Ship a standalone `powerbi-dependency-checking` skill with a Python script and thin PowerShell launcher.**
The implementation lives under `plugins/powerbi/skills/powerbi-dependency-checking/` and is independently invocable by any workflow. A `.ps1` launcher provides the repository's established Windows entry point while the Python script remains cross-platform. Alternative: place it in `semantic-model-authoring/scripts/`. Rejected because architecture and report-authoring need it too, and ownership by one workflow would hide the shared service.

**Use a directed, typed graph and explicit roots.**
Nodes use canonical identities including object type and model/table context; edges point from consumer to dependency. PBIR visual field references and governance objects form roots, and reachability runs from those roots. This makes both reverse impact lookup and unused-object detection simple and consistent. Alternative: perform ad hoc recursive text search per queried object. Rejected because it cannot reliably explain transitive paths or distinguish objects reachable only through other unused objects.

**Use Python's standard library for initial parsing.**
PBIR JSON is parsed with `json`; TMDL is ingested through a deliberately scoped parser/tokenizer that recognizes declarations and reference forms needed by the supported graph types. Avoiding a third-party parser keeps the skill installation-free and portable. Alternative: regex all files. Rejected because it cannot safely ignore comments/strings or retain object boundaries. Alternative: add a full DAX parser dependency. Deferred because it adds packaging complexity; unresolved reference syntax is surfaced as a diagnostic rather than guessed.

**Separate scan, impact, and output layers.**
The scanner loads project paths, ingestion produces graph nodes/edges plus diagnostics, analysis calculates roots/reachability/unused findings, and renderers emit text or JSON. The command surface exposes `scan` and `impact`, with `--json`, `--summary`, `--quiet`, and `--output`. This makes the graph fixtures unit-testable without subprocess calls. Alternative: one command that prints during traversal. Rejected because it couples analysis to human output and makes CI consumption brittle.

**Treat unused findings as advisory.**
Static analysis can miss dynamic DAX, external consumers, or metadata not represented in source. Findings are named `potentially unused`, include their known consumer explanation, and never cause automatic deletion. CI's exit code `1` is a policy signal a consuming pipeline can decide how to handle. Alternative: exit `0` always. Rejected because CI needs a reliable gate/signal without parsing output.

**Integrate through routing guidance, not direct coupling.**
Architecture and authoring skills route to dependency checking before rename, removal, or impact-sensitive changes; `dax-unit-testing` routes to it for coverage-impact review. The checker does not call those skills or their scripts. This prevents cyclic workflow dependencies and lets it be used in a lightweight preflight step.

## Risks / Trade-offs

- **[Risk]** TMDL/DAX syntax can contain dynamic or unsupported reference forms. → **Mitigation**: use fixtures for supported constructs, emit diagnostics for unrecognized constructs, and label results as static analysis.
- **[Risk]** PBIR schemas evolve and fields vary by visual type. → **Mitigation**: isolate PBIR extraction behind a parser module with versioned fixtures and retain source location metadata for evidence.
- **[Risk]** Conservative root selection may make objects look unused when an external consumer uses them. → **Mitigation**: support configured governance roots and state exactly why every object is considered potentially unused.
- **[Risk]** A standard-library TMDL parser could grow into an incomplete language implementation. → **Mitigation**: bound its contract to dependency extraction, tokenize rather than regex, and revisit a parser dependency only when a real unsupported construct blocks expected use.

## Migration Plan

Introduce the skill and its tests first, then add routing links to existing Power BI agents and skills. The existing report-reference scanner remains unchanged and available for its targeted search workflow. No project migration is required; consumers invoke the new script against local PBIP paths. Rollback removes the new skill and the routing links without altering PBIP source or existing workflows.
