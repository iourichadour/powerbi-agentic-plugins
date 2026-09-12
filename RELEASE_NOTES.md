# Release Notes

## `main` — merge `67d2cf9` (2026-09-10)
**Powerbi plugin bumped to v0.5.0**

### ✨ New: DAX Testing Framework (FIN-1787)
A complete unit-testing solution for Power BI semantic models, implementing all 45 tasks of the `integrate-pql-assert-dax-testing` OpenSpec change:

- **`dax-unit-testing` skill** — PQL.Assert assertion library + a measure certification registry (schema, TestCategory taxonomy, progressive Structural/Developer/Business approval lifecycle), legacy migration support, onboarding templates, and validate/generate/certify/coverage/setup scripts.
- **`dax-test-framework` skill** — dual-profile DEV (Desktop)/CLOUD (Fabric XMLA) execution, dynamic Desktop port discovery, mandatory smoke gate, CLI/pytest/notebook runners, JUnit/Markdown reporting, and an HTML test dashboard.
- **`pql-tester` agent** — new agent with setup/scan/sync/generate/run/report/diagnose modes, progressive-certification guardrails, and restricted write scope.
- Wired into `powerbi-architect`, `powerbi-developer`, `semantic-model-authoring`, README, AGENTS.md, and CLAUDE.md.
- 44 passing pytest tests; `openspec validate --strict` passes; benchmark evals added for both skills.

### 🐛 Fix: PBIP Reference-Search Discoverability
- `powerbi-report-authoring` skill now triggers correctly on phrases like "find all references," "where is this field used," "scan PBIP dependencies."
- Added explicit reference-search routing and result-classification rules (qualified/table-only/unrelated match logic).
- Plugin version bumped 0.3.0 → 0.4.0.

### 🛠️ Other
- New **troubleshooting-workflow** skill added under the `devops` plugin.
- Various OpenSpec planning docs and plugin version alignment.

### 📦 Included commits
`53d1a98`, `990d8af`, `a08bd7f`, `20009c7`, `8443227`, `ef1eebd`, `361cb48`, `f83bdaa`, `3da33e1`, `64eac7c`, `2b7ac23`, `67d2cf9`
