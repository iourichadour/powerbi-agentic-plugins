## 1. Bound the report-planning skill

- [x] 1.1 Rewrite the `powerbi-report-planning` frontmatter, introduction, and Must/Prefer/Avoid rules to define a planning-only workflow with plan-oriented triggers (drop "build me a dashboard" and "plan then implement") and remove the post-approval build, validation, and publishing sections; verify the skill no longer claims ownership of implementation or publishing
- [x] 1.2 Add the work-folder rules: create `specs/<JIRA>-<slug>/` (or `<slug>/`), take the Jira key from the git branch else ask once, derive the slug from the report name, never overwrite another report's `brief.md`; verify the approval output states the exact `brief.md` path and the skill stops after the approved brief
- [x] 1.3 Replace `assets/templates/report-spec.md` with a `brief.md` template with front-matter (`jira`, `report`, `status`, `mockup`), business context, model inventory, scope, page intent, design direction, model requirements, dependencies, constraints, risks, approval status, and architect handoff fields, plus a pre-approval completeness checklist; verify it contains no developer task checklist
- [x] 1.4 Add the optional design-mock input: sign-off counts as design approval, translation notes and field-binding gaps (as model requirements) are reviewed at approval, and the mock is never a gate; verify the skill does not claim generator or ingestion tooling

## 2. Wire the architect handoff

- [x] 2.1 Update `powerbi-architect.agent.md` so new-report specifications require an approved `brief.md` (route to planning if absent), model-only specifications are exempt, and the architect creates the work folder when no brief exists; verify EARS requirements, architecture, data sources, and executable tasks remain required
- [x] 2.2 Update the spec template: front-matter (`jira`, `report`, `status`, `mockup`), a `Design > Report Design Contract` subsection holding the verbatim `Design Brief:` YAML, EARS requirements citing it, one task per page, and a `Revisions` section (ADDED/MODIFIED/REMOVED)
- [x] 2.3 Add the rules: the spec's YAML is the only authoritative design; a revised mock updates the spec only on request through `powerbi-report-design`, with provenance recorded; design changes after execution starts append tasks and never reset completed ones
- [x] 2.4 Preserve specialist routing and the progressive measure-test task chain; verify the agent still references `powerbi-report-design`, `semantic-model-authoring`, `powerbi-report-authoring`, and `pql-tester` appropriately
- [x] 2.5 Sync the same changes into `powerbi-architect.toml`

## 3. Wire the developer contract

- [x] 3.1 Update `powerbi-developer.agent.md`: extract the embedded Design Brief for report-page tasks and pass it to `powerbi-report-authoring`, stop and ask the architect when it is missing, route layout changes through the architect, derive plan and summary paths from the spec's folder, and remove the planning "approval → build" wording; verify the Tasks lookup, acceptance-criteria validation, and execution-summary contract remain intact
- [x] 3.2 Sync the same changes into `powerbi-developer.toml`

## 4. Reconcile downstream references

- [x] 4.1 Update `powerbi-report-authoring/SKILL.md` and `powerbi-report-design/SKILL.md`, `references/design-brief.md`, and `references/pre-flight-checklist.md` so `_brief/report-spec.md` references become the Design Brief block in the approved spec; verify authoring and design skills still route direct requests without forcing planning
- [x] 4.2 Update `plugins/spec-lifecycle/README.md` and `openspec-bridge/SKILL.md` for the work-folder layout and the folder-based spec path
- [x] 4.3 Search the repository for remaining `_brief/report-spec.md`, flat `specs/<Name>.spec.md` references, and planning build/publish ownership claims; verify they are removed or clarified
- [x] 4.4 Verify direct design-only, surgical report-authoring, semantic-model, and report-management requests still route to their specialist skills without forcing the planning workflow

## 5. Document the process

- [x] 5.1 Update `plugins/powerbi/README.md`: add a "New report workflow" section with the optional design mock, planning, architect, and developer diagram, the work-folder layout, and artifact ownership; update the `powerbi-report-planning`, `powerbi-architect`, and `powerbi-developer` entries
- [x] 5.2 Update the root `README.md`: expand the "Spec driven development" scenario with the new-report path linking to the plugin README, and update the `spec-lifecycle` table row for the work-folder layout
- [x] 5.3 Verify both READMEs present the mock as optional and do not claim generation, ingestion, or binding tooling

## 6. Validate the contract

- [x] 6.1 Run `scripts/validate-codex-projection.ps1` and `scripts/validate-codex-catalog.ps1`, check skill frontmatter, and verify all referenced paths in the changed skills and agents resolve
- [x] 6.2 Run `openspec validate --strict --changes "separate-report-planning-from-implementation"` and verify the change passes schema validation
- [x] 6.3 Review the final planning-to-architect-to-developer flow against the capability scenarios and verify no project code, semantic-model artifact, PBIR artifact, or publishing operation was changed by this documentation-only change
- [x] 6.4 Update `setup-team-plugins.ps1`, `README.md`, `DEVELOPER_SETUP.md`, `TEAM_DEPLOYMENT_GUIDE.md`, and `AGENTS.md` so non-interactive Copilot verification uses `copilot plugin list`, while interactive guidance explicitly uses `/plugin list` inside a running session; verify MCP registration, per-user pinned-package provisioning, host-specific projection, and the Windows direct-Node launcher are documented.
- [x] 6.5 Shorten the `skill-merge-planner` frontmatter description to 1,024 characters or fewer without weakening its trigger boundary, then verify `copilot skill list` reports no bundled skill-load failures.
- [x] 6.6 Re-run `copilot plugin list`, `copilot skill list`, the Codex catalog/projection validators, the MCP provisioning/readiness smoke test, and `openspec validate --strict --changes "separate-report-planning-from-implementation"`; record plugin discovery, complete skill loading, generated MCP projection, pinned package provisioning, and successful MCP `initialize` as acceptance criteria.

## 7. Optimize dependency provisioning and backup retention

- [x] 7.1 Update `setup-team-plugins.ps1` to discover and validate an available ADOMD.NET dependency before downloading or installing it; reuse a usable installation, install only when missing or unusable, and verify both branches with isolated setup fixtures
- [x] 7.2 Add installer backup cleanup using a seven-day retention boundary; delete only artifacts older than seven days, preserve current artifacts, tolerate a missing backup directory, and verify the behavior with dated fixtures
- [x] 7.3 Make Codex MCP projection ownership-safe: create missing registrations, update installer-owned registrations, and fail without modifying non-installer-owned collisions; verify all three branches with isolated fixtures
- [x] 7.4 Update setup documentation and acceptance output to describe conditional ADOMD.NET provisioning, backup cleanup, and Codex collision remediation, then run the setup integration tests, MCP smoke test, and strict OpenSpec validation
