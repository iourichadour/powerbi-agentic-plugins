---
name: azure-devops-standard-branch-policy
description: Applies standard Azure DevOps branch policies to one or more branches for a repository after showing the plan and getting explicit user confirmation.
---

# Azure DevOps Standard Branch Policy (Windows)

## Purpose
Apply the team's standard Azure DevOps branch policies to one or more branches in a repository.

## Standard policy applied

### Always applied
1. Minimum approver count
2. Work item linking

### Conditionally applied
3. Build validation
   - only if a build definition ID is supplied

## Self-approval rule

### Protected branches
For these branches, self-approval is NOT allowed:
- main
- master
- prod

Behavior:
- creator-vote-counts = false
- minimum approvers = 2

### Non-production branches
For other branches, self-approval is allowed.

Behavior:
- creator-vote-counts = true
- minimum approvers = 1

## Inputs required
- Repository name
- Comma-separated branch names
- Optional Azure DevOps organization URL
- Optional Azure DevOps project
- Optional build definition ID

## Required behavior
Before making any changes, ALWAYS:
1. Resolve repository ID.
2. Parse target branches.
3. Show the user the exact plan.
4. Clearly indicate whether build validation will be applied or skipped.
5. Ask for explicit confirmation:
   - Proceed with applying these policies? (yes/no)
6. Only proceed if the user confirms.

## Script to run

On Windows / PowerShell environments:

```powershell
powershell -ExecutionPolicy Bypass -File apply_standard_branch_policies.ps1 `
  -Repo "<repo-name>" `
  -Branches "<dev,main>" `
  -Org "<https://dev.azure.com/yourorg>" `
  -Project "<project-name>" `
  -BuildDefinitionId "<build-id>"
```

On Bash-based environments (e.g. Claude Code):

```bash
bash apply_standard_branch_policies.sh \
  --repo "<repo-name>" \
  --branches "<dev,main>" \
  --org "<https://dev.azure.com/yourorg>" \
  --project "<project-name>" \
  --build-definition-id "<build-id>"
```

Both scripts are equivalent, native implementations — use whichever matches
the current environment. If org/project are already configured in Azure
DevOps CLI defaults, they may be omitted.

## Example prompts
- Apply standard branch policies to repo "skills-for-fabric" for dev and main, no build validation. Show plan first.
- Apply standard branch policies to repo "fabric-agent-repo" for main using build definition ID 42. Show plan first.
