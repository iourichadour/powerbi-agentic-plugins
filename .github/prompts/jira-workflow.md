# Sample prompts — jira-workflow

Copy-pasteable prompts that exercise `plugins/devops/skills/jira-workflow/SKILL.md`
(used together with `git-branch-guard` via the `devops` agent). See that
SKILL.md for the exact numbered algorithm these prompts trigger.

## Starting a ticket (MCP available)

```
I want to work on FIN-1740
```
```
let's work on FIN-1740
```
```
start FIN-1740
```
```
pick up FIN-1740
```

Expected agent behavior (SKILL.md Step 2): discovers the Jira MCP tools,
resolves the cloudId, fetches FIN-1740, assigns it to you, transitions it to
**In Progress**, slugifies the ticket summary into a branch short
description, then hands off to `git-branch-guard` to create
`feature/FIN-1740-<short-description>` (or `bugfix/...` if the ticket is a
bug).

## Finishing a ticket

```
I'm done with this ticket
```
```
I'm finished working on this
```
```
finished with FIN-1740
```
```
done with FIN-1740
```
```
ready to test FIN-1740
```

Expected agent behavior (SKILL.md Step 3): resolves the ticket key from your
message or from the current branch name, then transitions the ticket to
**Ready to Test**.

## Post-commit comment confirmation

After the agent runs `git commit`, expect it to ask:

```
Agent: Add a summary comment to the Jira ticket for this commit?
```

Sample replies:
```
yes
```
```
no
```

If you say yes, the agent posts a 1-3 sentence plain-English summary of the
change to the ticket (not the raw commit message).

## Fallback dialogue (no Jira/Atlassian MCP available)

```
I want to work on FIN-1740
```
```
Agent: The Jira/Atlassian MCP isn't available, so I can't fetch, assign, or
transition the ticket automatically.
Agent: What type of ticket is this — feature or bugfix?
User: feature
Agent: Give me a short kebab-case description for the branch name.
User: jira-mcp-integration
```

The agent then hands these two answers directly to `git-branch-guard` to
create `feature/FIN-1740-jira-mcp-integration`, with no further Jira MCP
calls attempted for the rest of the flow.
