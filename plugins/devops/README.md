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

## Skills

### `jira-workflow`

Fetches, assigns, and transitions Jira tickets via the Atlassian MCP when a
user starts work ("I want to work on FIN-1740" → assigns to the current user
and transitions to **In Progress**) or finishes work ("I'm done with this
ticket" → transitions to **Ready to Test**). After every commit, asks the
user whether to post a plain-English summary comment to the ticket. Falls
back to asking for ticket type (feature/bugfix) and a short description when
no Jira/Atlassian MCP is available. See
`.github/prompts/jira-workflow.md` for sample prompts.

### `git-branch-guard`

Validates that development starts on a `feature/` or `bugfix/` branch with a
Jira key and avoids protected branches. See
`.github/prompts/git-branch-guard.md` for sample prompts.

### `azure-devops-standard-branch-policy`

Applies the team standard Azure DevOps policy settings for non-production and protected branches.
