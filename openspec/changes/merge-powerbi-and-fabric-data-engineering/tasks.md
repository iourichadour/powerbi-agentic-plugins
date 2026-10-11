## 1. Reconcile the Power BI migration baseline

- [x] 1.1 Score every matched Power BI skill pair against all seven `skill-merge-planner` rubric dimensions and run `quick_validate.py` live on both candidates; verify the scorecard records the totals, dimension drivers, and actual validation output.
- [x] 1.2 Inventory local and upstream references, scripts, and assets for every matched pair, classify unique resources and unavailable dependencies, and record the recommended disposition; verify every inventory entry has a retain, graft, diff, exclude, or adapt decision.
- [x] 1.3 Obtain and record the user's confirmed or overridden base direction for every matched pair in `plans/skill-merge-fin-1810-powerbi-authoring.plan.md`; verify no merge implementation begins with an unreviewed disposition.
- [x] 1.4 Produce an ownership matrix for report authoring, management, planning, design, semantic-model authoring, FabricIQ, and Data Engineer/Migration Engineer; verify every scenario in `specs/powerbi/authoring-skill-migration/spec.md` has exactly one primary owner.
- [x] 1.5 Inventory local Power BI-only skills, scripts, templates, reference scanners, DAX testing resources, and agents before merging; verify the inventory has a path and preservation decision for every item.
## 2. Apply the approved selective Power BI merge

- [x] 2.1 Apply approved report-management improvements while retaining the local explicit Fabric REST/API update guidance; verify report CRUD and definition-transport triggers still resolve to report management.
- [x] 2.2 Add the approved semantic-model discovery improvement without adding an unresolved FabricIQ redirect; verify semantic-model definition and saved DAX changes still resolve to semantic-model authoring.
- [x] 2.3 Apply only the approved report-authoring, report-planning, and report-design changes; verify local scripts, templates, visual authoring, planning, and design routing remain reachable.
- [x] 2.4 Preserve or adapt every local-only Power BI resource identified in task 1.5; verify all retained relative references resolve and no installed skill contains a phantom upstream dependency.

## 3. Coordinate companion capabilities

- [x] 3.1 Add FabricIQ routing only after `add-fabriciq-consumption-skill` has passed its MCP connection and smoke-test gates; verify a business-data question routes to FabricIQ without changing report definitions.
- [x] 3.2 Add Data Engineer and Migration Engineer routing only after `port-fabric-data-engineering-capabilities` has delivered its selected skill closure; verify cross-workload requests retain the engineer as orchestrator and delegate semantic-model changes to the Power BI owner.
- [x] 3.3 Update relevant Power BI agents and package/catalog metadata with the approved boundaries; verify no agent duplicates a skill body or claims another capability's primary responsibility.

## 4. Project and validate multi-harness progressive disclosure

- [x] 4.1 Project the selected source-owned Power BI skills and agents to Codex, Claude Code, and GitHub Copilot CLI; verify each harness discovers the same intended capability names without duplicated canonical skill bodies.
- [x] 4.2 Validate referenced scripts, templates, and on-demand guidance from each harness projection; verify every selected skill resolves its local resources from the source-owned package.
- [ ] 4.3 Exercise targeted authoring, management, planning, design, semantic-model, FabricIQ, and data-engineering requests; verify each loads only its selected skill and required on-demand references rather than the full collection.

## 5. Complete FIN-1810 verification

- [x] 5.1 Run repository validation and the applicable skill/package checks after the selective merge; verify no broken links, invalid metadata, or routing conflicts are reported.
- [ ] 5.2 Reconcile the final implementation against this change and its two companion changes; verify every OpenSpec scenario is demonstrably satisfied or remains explicitly gated.
- [ ] 5.3 Update FIN-1810 with the final capability and verification summary after implementation is complete; verify the ticket distinguishes planning artifacts from completed implementation.
