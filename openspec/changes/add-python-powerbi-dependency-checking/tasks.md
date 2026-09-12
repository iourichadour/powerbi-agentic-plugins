## 1. Skill and Test Foundation

- [ ] 1.1 Create `plugins/powerbi/skills/powerbi-dependency-checking/` with `assets/scripts/`, `tests/`, and fixture PBIP directories, and verify the expected directory tree exists
- [ ] 1.2 Add `SKILL.md` with YAML frontmatter, supported local input paths, `scan`/`impact` command examples, output modes, limitations, and read-only behavior; verify frontmatter parses and links resolve
- [ ] 1.3 Create minimal fixture PBIP projects covering TMDL measures, calculated columns, hierarchies, relationships, partitions, perspectives, roles, and PBIR report/page/visual field references; verify fixture JSON and TMDL inputs load without parser errors

## 2. Static Graph Ingestion and Analysis

- [ ] 2.1 Implement Python project-path discovery for `.pbip`, project directory, `.SemanticModel`, `.Report`, and current-directory inputs, rejecting `.pbix`/`.pbit` with the documented unsupported-input error and exit code `2`; verify each supported input resolves the same fixture project
- [ ] 2.2 Implement canonical typed node identities, consumer-to-dependency edges, source locations, and graph serialization; verify graph unit tests cover node deduplication and directed edge creation
- [ ] 2.3 Implement scoped TMDL ingestion/tokenization for supported declarations and static DAX/model references; verify fixture tests identify direct measure, calculated-column, hierarchy, relationship, partition, perspective, and role dependencies while ignoring references in comments and string literals
- [ ] 2.4 Implement PBIR JSON ingestion to discover report/page/visual consumers of model fields and measures; verify fixture tests return the visual and its containing page/report for each expected reference
- [ ] 2.5 Implement root selection, reachability traversal, direct/transitive consumer lookup, dependency-path generation, and potentially-unused findings with consumer explanations; verify an unreferenced measure and a column consumed only by an unused hierarchy produce the specified results

## 3. Command and Output Contract

- [ ] 3.1 Implement the `scan` command with human-readable output containing project identity and object/root/reachable/unused counts; verify the fixture output includes every potentially unused finding and its explanation
- [ ] 3.2 Implement the `impact` command accepting a canonical model-object identity and returning direct dependencies, direct consumers, transitive consumers, and paths grouped by model versus report/page/visual consumers; verify a measure used by multiple visuals returns the complete downstream impact and an unknown identity returns the documented not-found error
- [ ] 3.3 Implement `--json`, `--summary`, `--quiet`, and `--output` modes using stable JSON fields (project, counts, roots, findings, graph/impact results); verify JSON snapshots and verify quiet scan emits no human-readable findings
- [ ] 3.4 Implement exit codes `0` (no unused findings), `1` (potentially unused objects found), and `2` (input/analysis error); verify all three paths with automated command-level tests
- [ ] 3.5 Add a Windows PowerShell launcher that finds Python 3.10+ without selecting the Windows Store alias and forwards arguments to the Python command; verify it runs `scan` against a fixture project

## 4. Workflow Routing

- [ ] 4.1 Update `plugins/powerbi/skills/semantic-model-authoring/SKILL.md` to route rename/removal and dependency-sensitive semantic-model changes to `powerbi-dependency-checking`; verify the workflow selector/reference table is formatted correctly
- [ ] 4.2 Update `plugins/powerbi/skills/powerbi-report-authoring/SKILL.md` to route report-impact checks to `powerbi-dependency-checking` while retaining the existing term-oriented `report_reference_scan.py` workflow; verify the two tools' distinct purposes are documented
- [ ] 4.3 Update `plugins/powerbi/skills/dax-unit-testing/SKILL.md` and `plugins/powerbi/agents/pql-tester.agent.md` to use dependency checking for test-coverage impact review, without coupling the scanner to certification/generation operations; verify routing is one-way and remains read-only
- [ ] 4.4 Update `plugins/powerbi/agents/powerbi-architect.agent.md` and `plugins/powerbi/agents/powerbi-developer.agent.md` to invoke dependency checking during architecture impact analysis and before dependency-sensitive edits; verify both treat findings as advisory evidence, not automatic deletion authority
- [ ] 4.5 Update `plugins/powerbi/README.md`, `AGENTS.md`, and `CLAUDE.md` to register the new standalone skill; verify every registry includes the same skill name and purpose

## 5. Final Verification

- [ ] 5.1 Run the complete Python test suite with `py -m unittest discover` (or the repository's selected test runner) and verify all parser, graph, command, and fixture tests pass
- [ ] 5.2 Run a representative `scan --json` and `impact` command against the fixture PBIP project and verify the exit code/output contracts match the capability spec
- [ ] 5.3 Confirm the scanner leaves PBIP/TMDL/PBIR fixture hashes unchanged after scan and impact operations
- [ ] 5.4 Run `openspec validate --strict --changes "add-python-powerbi-dependency-checking"` and verify no planning-artifact errors are reported
