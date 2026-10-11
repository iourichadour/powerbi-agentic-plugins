# DevOps

Team devops package for branch hygiene and Azure DevOps policy workflows.

## What it does

Activated when a user needs to start development on a safe branch or apply standard Azure DevOps branch policies to a repository.

|  |  |
|--|--|
| Branch guardrails | "Check my current branch before I start coding" |
| Jira ticket workflow | "I want to work on FIN-1740" |
| Azure DevOps policies | "Apply the standard branch policy to dev and main" |

## Agent

### `devops`

Activated for branch hygiene, Jira ticket workflow, and Azure DevOps policy
tasks. Uses the `jira-workflow`, `git-branch-guard`, and
`azure-devops-standard-branch-policy` skills to fetch/assign/transition Jira
tickets, validate branch names, enforce repository policy standards, and
guide safe team workflows.

### Sample install prompt

```text
Use @setup-team-plugins.ps1 -PluginName devops to install only the DevOps plugin.
```

For Claude Code: `.\setup-claude-plugins.ps1 -PluginName devops`

## Skills

### `jira-workflow`

Fetches, assigns, and transitions Jira tickets via the Atlassian MCP when a
user starts or finishes work. After branch validation, it always asks the user
to choose exactly **Bug**, **Report Development Story**, **Fabric Development**,
or **Other**; Jira metadata never selects the route. Report stories then choose
new report/dashboard, existing report change, model-only, or publishing/
management. New reports use the approved `brief.md` → `powerbi-architect`
canonical specification → explicit `powerbi-developer` handoff. Fabric
development uses a Jira-prefixed OpenSpec change, while bugs and investigative
Other work use the resumable `TROUBLESHOOTING.md` record. Planning never starts
implementation automatically, and cancellation leaves routing unresolved.

After every commit, the skill asks whether to post a plain-English summary
comment to the ticket. It falls back to asking for ticket type (feature/bugfix)
and a short description when no Jira/Atlassian MCP is available. See
`.github/prompts/jira-workflow.md` for sample prompts.

### `git-branch-guard`

Validates that development starts on a `feature/` or `bugfix/` branch with a
Jira key and avoids protected branches. See
`.github/prompts/git-branch-guard.md` for sample prompts.

### `azure-devops-standard-branch-policy`

Applies the team standard Azure DevOps policy settings for non-production and protected branches.
