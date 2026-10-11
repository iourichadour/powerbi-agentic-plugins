---
name: jira-workflow
description: Fetches, assigns, and transitions Jira tickets via the Atlassian MCP when a user starts or finishes work, and offers to post a commit summary comment. Falls back to a manual prompt when no Jira MCP is available.
---

# Jira Workflow (MCP-driven)

## Purpose

Automate the Jira side of starting and finishing ticket work, and posting
progress comments, using whatever Atlassian/Jira MCP server is connected in
the current session. This skill is written as a **strict numbered algorithm**.
Follow the steps in order, exactly as written. Do not skip steps. Do not
invent tool names. Do not guess status/transition IDs.

This skill does **not** create or validate git branches — that is the job of
the separate `git-branch-guard` skill. This skill only supplies
`ticket_key` and `short_description` to it (see Step 2.6).

## Dependencies

| Dependency | Purpose | Required When |
|---|---|---|
| `com.atlassian/atlassian-mcp-server` MCP server (primary, confirmed) | Fetch/assign/transition Jira tickets, add comments | Preferred — try first in Step 0 |
| `atlassian-rovo-mcp` MCP server (alternate name, some orgs) | Same as above | Only if the primary is not connected |
| `git` / `git-branch-guard` skill | Creates the branch using `ticket_key` + `short_description` | Always, after Step 2 |
| `git-branch-guard/assets/pbip-pr-summary/commit_diff_summary.ps1`/`.sh` | Grounded, structurally-diffed PBIP change summary for a single commit | Optional, Step 4.3.2 — only when the commit touches files under a `*.Report/` or `*.SemanticModel/` project folder |

`com.atlassian/atlassian-mcp-server` is the server actually registered in
this environment's `~/.copilot/mcp.json` / `mcp-config.json` (gallery entry,
endpoint `https://mcp.atlassian.com/v1/mcp`) and has been verified working
end-to-end (fetch, assign, transition, comment) in a prior session on
FIN-1740. Treat its tool names and parameter shapes below as **known-good
defaults** — do not re-derive them from scratch every time. If neither
server is connected, this skill degrades automatically to the **Fallback
algorithm** — this is expected, non-error behavior, not a failure to work
around.

---

## Step 0 — Confirm MCP tool names (single targeted search, not a fishing expedition)

The CLI's tool-search interface truncates long tool names, so the exact
string returned by `tool_search_tool` may not exactly match the theoretical
`com-atlassian-atlassian-mcp-server-<ToolName>` pattern — always use the
**exact string returned by the search**, never construct it by hand.

1. Make **one** `tool_search_tool` call with a combined regex covering every
   job this skill needs, anchored with `$` where the tool name could
   otherwise prefix-match a longer sibling tool name:
   ```
   pattern: "getAccessible|atlassianUserInfo|getJiraIssue$|getTransitionsForJiraIssue|transitionJiraIssue|editJiraIssue|addCommentToJiraIssue"
   limit: 10
   ```
   (`getJiraIssue$` avoids also matching `getJiraIssueRemoteIssueLinks` /
   `getJiraIssueTypeMetaWithFields`.)
2. Map the returned tool names to these 7 jobs by the distinctive suffix
   each contains — this is the known-good mapping, confirmed working:
   - site/cloudId discovery → tool whose name contains `getAccessible...` (site discovery tool)
   - get a single issue → tool whose name ends in `getJiraIssue`
   - list transitions → tool whose name ends in `getTransitionsForJiraIssue`
   - execute a transition → tool whose name ends in `transitionJiraIssue`
   - edit issue fields (assignee, etc.) → tool whose name ends in `editJiraIssue`
   - add a comment → tool whose name ends in `addCommentToJiraIssue`
   - current-user lookup → tool whose name ends in `atlassianUserInfo`
3. IF the combined search returns **zero** tools for all 7 jobs → retry once
   with the broader fallback pattern `jira|atlassian`.
   - IF that also returns zero tools → go directly to the **Fallback
     algorithm** at the bottom of this document, and stop. Do not attempt
     Steps 1-4.
4. Reuse the exact discovered tool names for the rest of this session — do
   not re-run `tool_search_tool` again once all 7 are resolved, and never
   call a tool name you have not confirmed exists in this session's search
   results.

## Step 1 — Resolve the Atlassian `cloudId` (once per session)

1. Call the site-discovery tool found in Step 0 with no arguments.
2. IF it errors, times out, or returns no site → go to the **Fallback
   algorithm** and stop.
3. The response is an array of resources; the same `id` (cloudId) commonly
   appears more than once with different `scopes` (e.g. one entry scoped to
   Confluence, another to `read:jira-work`/`write:jira-work`). Take the `id`
   value — it is the same cloudId regardless of which scoped entry you read,
   so the first entry is normally sufficient. Only ask the user which site
   to use if you see genuinely **different** `id` values (multiple distinct
   Atlassian sites).
4. Store the resolved `cloudId` value for this session. Reuse it in every
   subsequent Jira MCP call below — do not re-resolve it each time.

## Step 2 — Start-ticket trigger

**Trigger phrases** (case-insensitive match against the user's message; the
ticket key is any token matching the regex `[A-Z]+-\d+`):
- "I want to work on <KEY>"
- "let's work on <KEY>"
- "start <KEY>"
- "pick up <KEY>"
- "I'm starting <KEY>"

When one of these matches, extract `<KEY>` and do the following, in order.
**Parameter shapes below are confirmed from a live run — use them exactly,
do not invent alternate field names like `issue_key`, `assignee` (flat), or
`transition_id`:**

1. Call the get-issue tool with `{ cloudId, issueIdOrKey: <KEY> }`.
   - IF it errors (not found, permission denied, call fails) → tell the user
     the exact error text returned, then go to the **Fallback algorithm** and
     stop.
   - ELSE → store the issue's `fields.summary`, `fields.status.name`, and
     `fields.issuetype.name`.
2. Resolve the current user's Atlassian account id by calling the
   current-user tool (no arguments) → returns `account_id` (snake_case in
   this response).
   - IF no such tool exists, or it errors → ask the user directly: "What is
     your Atlassian account email?" Then call a user-lookup tool (found in
     Step 0) with that email to get the account id.
   - IF that also fails → tell the user: "I couldn't resolve your Atlassian
     account automatically — you'll need to assign this ticket to yourself
     manually in Jira." Continue to Step 2.4 anyway (do not treat this as a
     full MCP failure / do not go to Fallback).
3. IF an account id was resolved in Step 2.2 → call the edit-issue tool with
   `{ cloudId, issueIdOrKey: <KEY>, fields: { assignee: { accountId:
   <account_id> } } }` to assign the ticket to the current user. Note
   `assignee` is nested one level inside `fields`, and the key is
   `accountId` (camelCase) even though the lookup tool returned `account_id`.
   - IF it errors → tell the user the exact error text, but continue (do not
     stop the whole flow over an assignment failure).
4. Call the list-transitions tool with `{ cloudId, issueIdOrKey: <KEY> }`.
   - Search the returned `transitions[]` array, case-insensitively, for an
     entry whose `name` (or `to.name`) is exactly **"In Progress"**.
   - IF found → call the transition tool with `{ cloudId, issueIdOrKey:
     <KEY>, transition: { id: <the matched transitions[].id> } }`. Note the
     transition id is nested inside a `transition` object, not a flat
     `transition_id` field.
   - IF not found → tell the user, verbatim style: "No transition to 'In
     Progress' is available from the ticket's current status ('<current
     status>'). Available transitions are: <list the returned transition
     names>." Then ask the user to pick one of the listed names, or say
     "skip" to continue without transitioning. Never invent or force an
     unlisted transition id.
5. Take the issue's `summary` field (from Step 2.1) and slugify it: lowercase
   it, replace anything that is not `[a-z0-9]` with a single hyphen, collapse
   repeated hyphens, trim leading/trailing hyphens, and truncate to at most
   40 characters. This becomes `short_description`.
6. Hand off `ticket_key = <KEY>` and `short_description` (from Step 2.5) to
   the `git-branch-guard` skill so it can create/validate the
   `feature/<KEY>-<short_description>` or `bugfix/<KEY>-<short_description>`
   branch. Ask the user which of `feature` or `bugfix` applies if the
   ticket's `issuetype` (from Step 2.1) does not make it obvious (e.g.
   `issuetype` containing "Bug" → `bugfix`; anything else → `feature`).

## Step 3 — Finish-ticket trigger

**Trigger phrases** (case-insensitive):
- "I'm done with this ticket"
- "I'm finished working on this"
- "finished with <KEY>"
- "done with <KEY>"
- "ready to test <KEY>"
- "ready to test this ticket" (no key given)

When one of these matches:

1. Determine `<KEY>`:
   - IF the message contains a token matching `[A-Z]+-\d+` → use that as
     `<KEY>`.
   - ELSE → extract the ticket key from the current git branch name using
     the same regex `[A-Z]+-\d+` (this matches how `git-branch-guard` names
     branches: `feature/<KEY>-...` or `bugfix/<KEY>-...`). Run
     `git branch --show-current` if needed to read the branch name.
   - IF no key can be determined either way → ask the user: "Which ticket
     key should I transition?" and use their answer.
2. Call the list-transitions tool with `{ cloudId, issueIdOrKey: <KEY> }`.
   - Search case-insensitively for a transition whose `name` is exactly
     **"Ready to Test"**.
   - IF found → call the transition tool with `{ cloudId, issueIdOrKey:
     <KEY>, transition: { id: <matched id> } }`.
   - IF not found → use the same explicit message pattern as Step 2.4,
     substituting "Ready to Test" for "In Progress".

## Step 4 — Post-commit comment trigger

Run this after **every** `git commit` the agent performs during this
session, in order:

1. Ask the user directly, verbatim: "Add a summary comment to the Jira
   ticket for this commit?"
2. IF the user answers no / declines → do nothing further; continue with
   whatever comes next.
3. IF the user answers yes:
   1. Determine `<KEY>` using the exact same procedure as Step 3.1.
   2. IF the commit touched any files under a `*.Report/` or
      `*.SemanticModel/` project folder → run
      `../git-branch-guard/assets/pbip-pr-summary/commit_diff_summary.ps1`
      (or `.sh`) with no arguments (it defaults to `HEAD~1..HEAD`) to get a
      grounded, structurally-diffed bullet list instead of reading the raw
      JSON yourself — UI/JSON changes (slicer field order, formatting,
      filters) are unreliable to summarize by eye. Use its output as the
      basis for the summary below; if the script errors or isn't available,
      fall back to reading the diff directly.
   3. Write a 1-3 sentence **plain-English summary** of what the commit
      changed and why — a human-readable explanation, not the raw commit
      message or diff pasted verbatim.
   4. Call the add-comment tool with `{ cloudId, issueIdOrKey: <KEY>,
      commentBody: <the plain-English summary> }`. Note the body parameter
      is named `commentBody`, not `body`.
      - IF it errors → tell the user the exact error text and that they
        should add the comment manually in Jira. Do not retry silently and
        do not fail the rest of the task over this.

---

## Fallback algorithm (used whenever a step above says "go to Fallback")

1. Tell the user plainly: "The Jira/Atlassian MCP isn't available, so I
   can't fetch, assign, or transition the ticket automatically."
2. Ask the user two explicit questions:
   1. "What type of ticket is this — feature or bugfix?"
   2. "Give me a short kebab-case description for the branch name."
3. Hand off the user's two answers directly to `git-branch-guard` to
   create/validate the branch, exactly as it works today. Do not attempt any
   further Jira MCP calls for the rest of this flow (Steps 1-4 above are
   skipped entirely in fallback mode; Step 4's post-commit prompt should
   still be offered, but if the user says yes, tell them the comment can't
   be posted automatically and they should add it manually in Jira).

---

## Worked example (Steps 0-2, MCP available — reproduced from a real run)

```
User: I want to work on FIN-1740

Agent (Step 0): [calls tool_search_tool with the combined pattern]
  -> finds (names truncated by the CLI's search index, use verbatim):
     com-atlassian-atlassian-mcp-server-getAccessibleAtlassianResourc
     com-atlassian-atlassian-mcp-server-getJiraIssue
     com-atlassian-atlassian-mcp-server-getTransitionsForJiraIssue
     com-atlassian-atlassian-mcp-server-transitionJiraIssue
     com-atlassian-atlassian-mcp-server-editJiraIssue
     com-atlassian-atlassian-mcp-server-addCommentToJiraIssue
     com-atlassian-atlassian-mcp-server-atlassianUserInfo

Agent (Step 1): [calls the getAccessibleAtlassianResourc tool, no args]
  -> two entries returned, both with the same id, different scopes
  -> cloudId = "b3fcc1a7-23ed-45d2-a353-ebd4c9f5043e"

Agent (Step 2.1): [calls getJiraIssue({ cloudId, issueIdOrKey: "FIN-1740" })]
  -> fields.summary = "Update Agentic tooling for developers to
     automatically link to relevant jira and create latest comments on
     jira ticket"
  -> fields.status.name = "Not Started", fields.issuetype.name = "Story"

Agent (Step 2.2): [calls atlassianUserInfo, no args]
  -> account_id = "712020:35e0a254-a41b-4606-8895-efa6b7c6aed1"

Agent (Step 2.3): [calls editJiraIssue({ cloudId, issueIdOrKey: "FIN-1740",
  fields: { assignee: { accountId: "712020:35e0a254-a41b-4606-8895-efa6b7c6aed1" } } })]
  -> success, fields.assignee now reflects the current user

Agent (Step 2.4): [calls getTransitionsForJiraIssue({ cloudId, issueIdOrKey: "FIN-1740" })]
  -> finds transitions[] entry { id: "31", name: "In Progress" }
  [calls transitionJiraIssue({ cloudId, issueIdOrKey: "FIN-1740",
  transition: { id: "31" } })] -> success, fields.status.name = "In Progress"

Agent (Step 2.5): slugify summary ->
  "update-agentic-tooling-for-developers-to-autom" (truncated to 40 chars)

Agent (Step 2.6): hands off ticket_key="FIN-1740",
  short_description="update-agentic-tooling-for-developers-to-autom" to
  git-branch-guard, asks: "This looks like a Story — should the branch be
  feature/ or bugfix/?" -> user says feature ->
  git-branch-guard creates feature/FIN-1740-update-agentic-tooling-for-developers-to-autom
```
