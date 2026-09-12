## 1. Branch-existence check (devops/git-branch-reuse)

- [x] 1.1 In `plugins/devops/agents/devops.agent.md` Step 1, add a sub-step between receiving `ticket_key` from `jira-workflow` and invoking `git-branch-guard`: run `git branch --list "*<KEY>*"` and (after `git fetch --quiet`) `git branch -r --list "*<KEY>*"` to search for an existing branch containing the ticket key. Verify by re-reading the updated agent doc and confirming the new sub-step is numbered and ordered correctly relative to the existing Step 1 sub-steps.
- [x] 1.2 Document the fallback behavior when `git fetch` fails (e.g., offline): fall back to local + last-known remote-tracking refs and tell the user the remote search may be stale. Verify the wording appears in `devops.agent.md`.
- [x] 1.3 Add the "no match found" and "match found" branch logic to the same agent step: no match → proceed to `git-branch-guard` as today; match found → tell the user the branch already exists and ask whether to switch to it. Verify both paths are documented with explicit example agent responses.
- [x] 1.4 Add the "user declines switching" path: do not auto-create a duplicate branch; ask the user how to proceed (e.g., different description). Verify this is documented as a distinct outcome from "user agrees to switch".
- [x] 1.5 Update `plugins/devops/skills/git-branch-guard/SKILL.md`'s "Related skill: jira-workflow" section to reference the new pre-creation existence check owned by the `devops` agent, so the skill doc and agent doc stay consistent. Verify by reading both files side by side for contradictions.
- [x] 1.6 Manually walk through all four scenarios from `specs/devops/git-branch-reuse/spec.md` against the updated `devops.agent.md` text and confirm each scenario's WHEN/THEN is satisfied by the documented steps.

## 2. PR-creation script asset (devops/pr-creation)

- [x] 2.1 Create `plugins/devops/skills/git-branch-guard/assets/create_pr.ps1` (PowerShell) accepting `-Repo`, `-SourceBranch`, `-TargetBranch` (default `DEV`), `-Title`, optional `-Org`, `-Project`. Verify the script parses parameters correctly with `Get-Help` or a `-WhatIf`-style dry run print of the resolved plan, and that `powershell -ExecutionPolicy Bypass -File create_pr.ps1 ...` runs it directly.
- [x] 2.2 Implement source-branch/Jira-key auto-resolution from the current branch when `-SourceBranch`/`-Title` are not passed explicitly. Verify by running the script from a `feature/FIN-1813-...` branch with no `-SourceBranch` argument and confirming it resolves the branch name correctly.
- [x] 2.3 Implement the plan-printing step (repo, source branch, target branch, title) that always runs before the `az repos pr create` call, with no interactive prompt inside the script itself (confirmation is owned by the calling agent turn). Verify the printed plan matches the arguments passed.
- [x] 2.4 Implement the `az repos pr create --repository <Repo> --source-branch <SourceBranch> --target-branch <TargetBranch> --title <Title> [--org ...] [--project ...]` call and surface raw CLI stderr/errors on failure instead of swallowing them. Verify by running against a test repo/branch pair and confirming both a success case and an intentional failure case (e.g., no diff between branches) print useful output.
- [x] 2.5 Add a prerequisite check at the top of the script (or as a documented pre-check in the skill) that verifies the `azure-devops` extension is installed and the CLI session is authenticated, reporting the specific missing prerequisite rather than failing silently. Verify by simulating a missing-extension case (or documenting the exact error text `az` returns) and confirming the script's message matches.

## 3. PR-creation orchestration (devops agent)

- [x] 3.1 Update `plugins/devops/agents/devops.agent.md` Step 3 (post-commit) to add an independent sub-step: if the current branch matches the ticket-branch pattern, ask the user "Would you like to open a PR for this branch?" as a separate yes/no from the existing Jira-comment offer. Verify by reading the updated Step 3 and confirming the two questions are documented as distinct, independently skippable prompts.
- [x] 3.2 Add a new explicit-request trigger (e.g., "create a PR", "open a PR for this") to `devops.agent.md`'s orchestration list, routing to the same PR plan → confirm → `create_pr.ps1` flow. Verify the trigger phrases are listed alongside the existing start/finish-ticket trigger phrases for consistency.
- [x] 3.3 Document the default-target-branch resolution in `devops.agent.md`: default to `DEV` when the source is a ticket branch, but use the user's stated target if provided, before invoking `create_pr.ps1`. Verify by tracing through both the "no target specified" and "user specifies target" scenarios from `specs/devops/pr-creation/spec.md`.
- [x] 3.4 Document the confirmation gate explicitly in `devops.agent.md`: the agent must show the resolved plan (repo, source, target, title) and get an explicit yes before calling `create_pr.ps1`; a "no" answer ends the flow with no script invocation. Verify by re-reading the added text against the "PR plan must be shown and confirmed" requirement's three scenarios.
- [x] 3.5 Manually walk through all requirements and scenarios in `specs/devops/pr-creation/spec.md` against the updated `devops.agent.md` and `create_pr.ps1` and confirm each is satisfied.

## 4. Azure DevOps CLI dependency documentation

- [x] 4.1 Add an "Azure DevOps CLI" dependency entry to `plugins/devops/skills/git-branch-guard/SKILL.md` (extension, authenticated session, default organization/project), cross-referencing `assets/azure-devops-cli-setup.md` for the one-time setup steps. Verify by confirming the new section exists and links correctly.
- [x] 4.2 Add the same dependency to the `devops.agent.md` "Dependencies" table (alongside the existing Atlassian MCP and Git/PowerShell rows). Verify the table renders correctly and lists the Azure DevOps CLI as required specifically for PR creation, not for branch validation.
- [x] 4.3 Create `plugins/devops/skills/git-branch-guard/assets/setup_azure_cli.ps1` (idempotent PowerShell) automating the download/unzip/PATH/extension/defaults steps documented in `assets/azure-devops-cli-setup.md`. Verified by re-running it on a fully-configured machine — every step reported "already installed/configured" with exit code 0, including a real `az devops project list` call.

## 5. Validation

- [x] 5.1 Run `openspec validate add-devops-pr-and-branch-reuse --strict` and resolve any reported issues. Verify the command prints "is valid" with no errors.
