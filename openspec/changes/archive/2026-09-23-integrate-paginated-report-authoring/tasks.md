## 1. Vendor and adapt the upstream skill

- [x] 1.1 Copy the 11 files from microsoft/skills-for-fabric PR #65 commit `1e42d58` into `plugins/powerbi/skills/paginated-report-authoring/`, preserving references and scripts; verify the expected file tree and source attribution are present
- [x] 1.2 Adapt `SKILL.md` frontmatter, trigger wording, repository-relative links, common-document references, tool prerequisites, and authentication guidance to this repository; verify all referenced local paths resolve and no upstream-only path remains
- [x] 1.3 Review `gen_rdl.py` and `publish.ps1` for repository conventions, parameter handling, explicit overwrite behavior, token safety, and error propagation; verify static inspection finds no hardcoded credentials or identifiers

## 2. Integrate plugin and agent routing

- [x] 2.1 Update `powerbi-developer.agent.md` to route RDL/paginated-report requests to the new skill while retaining PBIR/PBIP routing; verify the agent lists both skills with non-overlapping trigger examples
- [x] 2.2 Update `plugins/powerbi/README.md`, root capability documentation, and plugin metadata/enumerations where applicable; verify documentation names the new skill and its supported workflows
- [x] 2.3 Check installation/package discovery behavior for the Power BI plugin and adjust only required manifests or indexes; verify the skill is included by the normal plugin installation path

## 3. Add offline validation and tests

- [x] 3.1 Add focused tests for RDL generator inputs, required namespaces/order, DAX field-name mapping, parameters, layout counts, and XML well-formedness; verify the focused test suite passes without Fabric credentials
- [x] 3.2 Add tests or validation checks for publisher safety and failure handling, including no-secret output, terminal operation failures, and explicit first-publish versus overwrite behavior; verify failure cases do not report false success
- [x] 3.3 Add skill metadata and routing discoverability checks for representative paginated and interactive report prompts; verify paginated prompts select the new skill and PBIR prompts remain on the existing skill

## 4. Verify and hand off

- [x] 4.1 Run repository formatting, skill/frontmatter validation, focused tests, and relevant existing Power BI tests; verify all pass and record any unavailable optional tools
- [x] 4.2 Perform a local dry run that generates a sample RDL from fixture inputs and parses it without publishing; verify generated files contain no secrets and are reproducible
- [x] 4.3 Review the final diff against PR #65 and the OpenSpec requirements, documenting intentional adaptations and confirming no existing PBIR/PBIP behavior changed
