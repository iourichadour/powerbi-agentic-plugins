---
name: git-branch-guard
description: Ensures development starts on a valid bugfix/ or feature/ branch that includes a Jira ticket number.
---

# Git Branch Guard (Windows)

## Purpose
Validate that development starts on a separate working branch and not on a protected branch.

## Mandatory rule
This check must run before:
- code changes
- SQL / DAX changes
- Fabric development
- semantic model updates
- notebook or pipeline edits
- documentation changes tied to implementation work

## Branch requirements
A valid development branch must:
1. Not be a protected or shared branch:
   - main
   - master
   - prod
   - production
   - dev
   - develop
2. Follow the preferred pattern:
   - `bugfix/JIRA-123-short-description`
   - `feature/JIRA-123-short-description`
3. Include a Jira ticket key in uppercase format:
   - `ABC-123`

## Expected behavior
1. Detect the current Git branch.
2. Fail if the branch is protected.
3. Fail if the branch does not contain a Jira ticket.
4. Fail if the branch does not start with `bugfix/` or `feature/`.
5. Suggest a compliant replacement branch name.
6. Do not proceed to implementation until the branch check passes.

## Script to run

```powershell
powershell -ExecutionPolicy Bypass -File check_git_branch_guard.txt
```

## Example valid branches
- bugfix/BI-123-fix-allocation-bug
- feature/DATA-456-add-audit-table

## Example invalid branches
- dev
- main
- feature/test
- drv/no-ticket

## Related skill: jira-workflow

This skill only validates/creates branch names — it does not talk to Jira.
When a user starts work on a ticket (e.g. "I want to work on FIN-1740"), the
`devops` agent invokes the `jira-workflow` skill **first** to
fetch/assign/transition the ticket via the `atlassian-rovo-mcp` or
`com.atlassian/atlassian-mcp-server` MCP server (see
`plugins/devops/skills/jira-workflow/SKILL.md` Step 0), then hands this
skill the resulting `ticket_key` + `short_description` to build the branch
name. If neither MCP server is connected, `jira-workflow` falls back to
asking the user directly for ticket type + description, which are passed to
this skill unchanged.
