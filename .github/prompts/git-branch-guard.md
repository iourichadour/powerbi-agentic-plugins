# Sample prompts — git-branch-guard

Copy-pasteable prompts that exercise
`plugins/devops/skills/git-branch-guard/SKILL.md` directly, and prompts
showing how it is invoked automatically as the second half of the
`jira-workflow` flow (see `.github/prompts/jira-workflow.md`).

## Direct usage (no Jira ticket context)

```
Check my current branch before I start coding
```
```
Validate my branch name
```

Expected agent behavior: runs
`check_git_branch_guard.txt`, reports whether the current branch is
protected, missing a Jira key, or missing the `feature/`/`bugfix/` prefix,
and suggests a compliant replacement name if it fails.

## Manual branch creation (no MCP involved)

```
Create a branch for FIN-1740, it's a feature, call it jira-mcp-integration
```

Expected agent behavior: creates
`feature/FIN-1740-jira-mcp-integration` directly, without invoking
`jira-workflow` (use this when you already know the ticket details and don't
need Jira fetched/assigned/transitioned).

## Combined usage (jira-workflow → git-branch-guard)

```
I want to work on FIN-1740
```

Expected agent behavior: `jira-workflow` (see
`.github/prompts/jira-workflow.md`) fetches/assigns/transitions the ticket
first, derives `ticket_key` and `short_description` from the ticket
summary, and then invokes `git-branch-guard` with those exact values to
create the branch — you should not need to type the branch name yourself in
this flow.
