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

On Windows / PowerShell environments:

```powershell
powershell -ExecutionPolicy Bypass -File check_git_branch_guard.ps1
```

On Bash-based environments (e.g. Claude Code):

```bash
bash check_git_branch_guard.sh
```

Both scripts are equivalent, native implementations — use whichever matches
the current environment.

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
`plugins/devops/skills/jira-workflow/SKILL.md` Step 0), then — before
handing off to this skill — searches for an existing local/remote branch
matching the resulting `ticket_key` (a pre-creation existence check owned
by the `devops` agent's own orchestration, not by this skill; see
`devops.agent.md` Step 1) and offers to switch to it instead of creating a
duplicate. Only when no existing branch match is found (or the user
declines switching in favor of a new name/description) does the agent hand
this skill the resulting `ticket_key` + `short_description` to build the
branch name. If neither MCP server is connected, `jira-workflow` falls back
to asking the user directly for ticket type + description, which are passed
to this skill unchanged.

## Note: assets/pbip-pr-summary/

This folder holds a standalone PBIP/PBIR change-summary tool (not part of
branch validation). It lives here only because skills are the unit that
gets distributed on install — a top-level repo `assets/` folder is not
scanned by the skill-loading mechanism, so tooling has to live inside a
skill's own folder to travel with it.

The tool is consumed in two ways:

1. **Automatic workflow** (jira-workflow Step 4.3.2): After a commit, when
   the user approves posting a summary comment to Jira, the tool generates
   a deterministic PBIP change summary.
   
2. **Explicit trigger** (devops agent Step 4): When the user requests
   "generate commit summary" or "generate PR summary" (case-insensitive),
   the devops agent routes to `.github/prompts/pbip-commit-or-pr-message.prompt.md`,
   which invokes this tool to synthesize a Jira-prefixed commit message
   or PR description. The user must explicitly request the generation
   or explicitly approve posting — no auto-posting in this mode.

See `plugins/devops/skills/jira-workflow/SKILL.md` for the automatic flow
and `devops.agent.md` Step 4 for the explicit trigger.

## Note: assets/azure-devops-cli-setup.md

One-time, per-machine setup steps for the Azure CLI (`az`) + `azure-devops`
extension that PR-creation tooling in this skill depends on (extension
install, `az login`, `az devops configure --defaults organization=...`).
It lives here — not in a top-level repo `plans/` folder — for the same
distribution reason as `assets/pbip-pr-summary/` above: only files inside a
skill's own folder travel with the plugin when installed elsewhere. The
accompanying `assets/setup_azure_cli.ps1` automates it end to end.

## Dependency: Azure DevOps CLI

PR creation (`assets/create_pr.ps1`) requires the Azure DevOps CLI to be
installed and ready:
- The `az` CLI itself, plus the `azure-devops` extension (`az extension add
  --name azure-devops`).
- An authenticated session (`az login`).
- Default `organization`/`project` configured (`az devops configure
  --defaults organization=... project=...`), or the equivalent `-Org`/
  `-Project` values passed explicitly to `create_pr.ps1`.

This is a one-time, per-machine setup — see
`assets/azure-devops-cli-setup.md` for the manual steps and
`assets/setup_azure_cli.ps1` for an idempotent script that automates all of
them. Branch validation/creation (`check_git_branch_guard.ps1`) does not
depend on the Azure DevOps CLI; only PR creation does.

