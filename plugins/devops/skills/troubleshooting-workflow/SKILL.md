---
name: troubleshooting-workflow
description: Runs the full ticket-to-resolution troubleshooting loop — Jira intake, branch setup, code/data-flow tracing, live-query root-cause confirmation, a living TROUBLESHOOTING.md log, and a Jira findings comment. Use this whenever the user asks to troubleshoot, investigate, or debug a bug/incident/ticket, wants to find out "why is X happening", asks to "start a troubleshooting session", requests root-cause analysis, or references a Jira-style ticket key (e.g. FIN-1806) alongside a symptom. Installed once in the devops plugin and reused unchanged across every repo — only the TROUBLESHOOTING.md log and repo memory pointer it creates are repo-specific.
---

# Troubleshooting Workflow

## Purpose

Turn ad-hoc bug investigations into a repeatable, resumable loop: pick up the
ticket, branch correctly, trace the real data/code flow, confirm root cause
against live data (not guesses), leave a durable written trail in the repo,
and report back to Jira. This skill is written as a **strict numbered
algorithm** — follow the steps in order. It does not duplicate the Jira or
branch logic already solved elsewhere; it **chains into**
`jira-workflow` and `git-branch-guard` at the right points instead.

This skill is designed to be installed once and used, unchanged, in every
repo. The algorithm below never changes per-repo. What *is* repo-specific —
the `TROUBLESHOOTING.md` log, the `/memories/repo/` pointer file, and any
live-query connection details — is bootstrapped fresh the first time this
skill runs in a given repo (Steps 3-4) and grows over time as more tickets
are investigated there. Never hardcode a repo's server names, workspace
names, or connection strings into this file — those belong only in that
repo's own `TROUBLESHOOTING.md`.

## Dependencies

| Dependency | Purpose | Required When |
|---|---|---|
| `jira-workflow` skill | Fetch/assign/transition the ticket to "In Progress" (Step 1), and post the findings comment + offer the next transition (Step 9) | Always — falls back to its own manual prompt if no Atlassian MCP is connected |
| `git-branch-guard` skill | Create/validate the `feature/`/`bugfix/` branch for the ticket | Always, right after Step 1 |
| A live-query tool matching the repo's data platform (`mssql` MCP, Fabric MCP, a DAX/Power BI MCP, Postgres, etc.) | Confirm or refute root-cause candidates against real data | Step 6-7 — discovered per-repo, never assumed |
| `tool_search_tool` (or equivalent MCP discovery) | Find the right live-query tool for this repo's platform | Step 6b, only when no working connection is already documented |

## Step 0 — Identify the ticket

1. Extract a ticket key from the user's message using the regex
   `[A-Z]+-\d+` (e.g. `FIN-1806`).
2. IF no key is found → ask the user for it directly. Do not proceed on a
   guess — a wrong ticket key corrupts the Jira handoff in Step 1 and 9.

## Step 1 — Start the ticket (hand off to `jira-workflow`)

1. Invoke `jira-workflow` Step 2 ("start-ticket" flow) with the ticket key
   from Step 0. It will fetch the issue, assign it to the current user, and
   transition it to "In Progress" — or fall back to asking the user
   manually if no Atlassian MCP is connected. Reuse whatever it returns
   (`short_description`, issue type) rather than re-deriving it yourself.

## Step 2 — Get on the right branch (hand off to `git-branch-guard`)

1. Invoke `git-branch-guard` with the `ticket_key` and `short_description`
   returned from Step 1 to create/validate the
   `feature/<KEY>-<description>` or `bugfix/<KEY>-<description>` branch.
   Do not begin investigation (Step 5 onward) until this passes.

## Step 3 — Bootstrap or resume this repo's `TROUBLESHOOTING.md`

1. Check the repo root for `TROUBLESHOOTING.md`.
2. IF it does not exist → create it from
   `assets/TROUBLESHOOTING.template.md` (copy verbatim; it already contains
   the "How to use this file" section and a placeholder "Standard
   troubleshooting environment" section for this repo to fill in over
   time). This is the *first-run bootstrap* for this repo — it happens once
   and never needs repeating.
3. IF it already exists → read it **in full** before doing anything else.
   Look for an existing `##` section matching this ticket key or a
   closely-related symptom. Investigating without reading this file first
   risks re-discovering facts (working connection profiles, prior root
   causes, ruled-out candidates) that a previous session already nailed
   down — that wasted effort is exactly what this file exists to prevent.
   - IF a matching section exists → treat it as the starting point. Append
     to it as new evidence comes in rather than starting a fresh
     investigation from zero.
   - IF no matching section exists → you'll create a new `##` section for
     this ticket in Step 8.

## Step 4 — Check repo memory for prior conventions

1. Check `/memories/repo/` for a troubleshooting-convention pointer file
   (created alongside `TROUBLESHOOTING.md` — see
   `assets/repo-memory-convention.template.md`) and any other repo-memory
   notes.
2. IF present → read it before doing fresh discovery. It exists to hold
   durable facts (e.g. which environment/workspace to query, known
   gotchas) that are cheaper to remember than to rediscover every session.
3. IF absent (first run in this repo) → create it from
   `assets/repo-memory-convention.template.md` now, alongside the
   `TROUBLESHOOTING.md` bootstrap in Step 3.

## Step 5 — Trace the actual data/code flow

1. Use `semantic_search`/`grep_search`/an `explore` subagent to trace the
   real flow implicated by the symptom — source system → ingestion →
   transform → storage → semantic model/report, or the equivalent for the
   repo's stack. Build a ranked list of root-cause candidates, each backed
   by a concrete file and line reference. A candidate described only in
   prose ("the pipeline probably drops late rows") is not usable evidence —
   trace it to the actual code or config that would cause that behavior.

## Step 6 — Choose a live-query tool (generic decision tree)

This decision tree deliberately names no specific server — the right tool
depends entirely on what this repo's data platform actually is.

1. **Check first**: does this repo's `TROUBLESHOOTING.md` "Standard
   troubleshooting environment" section (Step 3) already document a working
   connection (server, database, tool name)? If so, use it directly and
   skip to Step 7 — don't rediscover what a previous session already
   confirmed.
2. **If not documented yet**: call `tool_search_tool` for MCP tools matching
   this repo's actual data platform (e.g. `mssql` for SQL Server/Fabric
   Warehouse endpoints, a Fabric/Power BI MCP for lakehouses or semantic
   models, Postgres/MySQL-specific tools, etc.). Try the tool that matches
   what this repo is actually built on — read the repo's own docs or
   connection config if it's not obvious from context.
3. **On a successful connection**: immediately write the working
   server/database/tool details back into `TROUBLESHOOTING.md`'s
   "Standard troubleshooting environment" section (Step 8 will also update
   the ticket-specific section, but the environment facts belong in the
   shared section so every future ticket benefits). Skipping this write
   means the next session repeats this same discovery work.
4. **If every attempt fails**: do not guess at a connection or fabricate
   query results. Tell the user plainly which tools were tried and why they
   failed, and ask them how to connect. Document the blocker in
   `TROUBLESHOOTING.md` rather than leaving it unwritten.

## Step 7 — Confirm or refute candidates against live data

1. Run read-only (`SELECT`-only, or equivalent non-mutating) queries via
   the tool chosen in Step 6 to test each root-cause candidate from Step 5.
2. Only mark a candidate "confirmed" when live data actually supports it —
   row counts, specific values, or absence of expected records. A candidate
   is "ruled out" only when live data actively contradicts it, not merely
   because it seems less likely.
3. Do not mark the overall investigation resolved without at least one
   confirmed candidate backed by live-query evidence.

## Step 8 — Update `TROUBLESHOOTING.md` in place

1. Write (or update) a single `##` section for this ticket containing:
   symptom, data flow traced, root-cause candidates (ranked, with
   file/line evidence), the live-query confirmation/refutation results,
   current status, and an "Actions taken this session" log line.
2. Never duplicate a section for the same ticket — edit the existing one in
   place if Step 3 found one, so the file stays a single source of truth
   per ticket rather than accumulating stale duplicates.
3. If Step 6 discovered new environment facts, confirm they were written to
   the shared "Standard troubleshooting environment" section (not just the
   ticket's own section).

## Step 9 — Report back to Jira (hand off to `jira-workflow`)

1. Invoke `jira-workflow` Step 4 (post-commit-style comment flow, or its
   equivalent findings-comment step) to post a plain-English summary of
   what was found — mirroring the `TROUBLESHOOTING.md` section, not a raw
   dump of query output.
2. Ask the user whether to transition the ticket to its next state (e.g.
   "Ready to Test"). **Never transition past "In Progress" automatically,
   even when the root cause is fully confirmed** — the user may want to fix
   the issue first, defer it, or route it differently. Use
   `jira-workflow` Step 3 only after the user explicitly confirms which
   transition they want.

## Worked example (compressed)

```
User: investigate FIN-1806, current month is stuck on July instead of August

Step 0: ticket key = FIN-1806
Step 1: jira-workflow assigns + transitions FIN-1806 to "In Progress"
Step 2: git-branch-guard creates feature/FIN-1806-research-current-month-data
Step 3: TROUBLESHOOTING.md doesn't exist yet -> bootstrapped from template
Step 4: /memories/repo/ has no convention file yet -> bootstrapped from template
Step 5: traced CDC copy -> lakehouse table -> notebook gate -> semantic model;
        found two ranked candidates with file/line references
Step 6: TROUBLESHOOTING.md has no documented connection yet -> tool_search_tool
        finds an mssql-style MCP -> connects to the TEST lakehouse SQL endpoint
        -> writes the working connection into the shared environment section
Step 7: live SELECT queries show August exists but is missing 2 of 4 required
        portfolios -> confirms candidate #1, rules out candidate #2
Step 8: TROUBLESHOOTING.md gets a new "## FIN-1806" section with the full
        finding, confirmed root cause, and evidence
Step 9: jira-workflow posts a plain-English comment to FIN-1806; agent asks
        the user whether to transition to "Ready to Test" rather than
        assuming
```

## See also

- `assets/TROUBLESHOOTING.template.md` — the generic per-repo log skeleton
  bootstrapped in Step 3.
- `assets/repo-memory-convention.template.md` — the generic
  `/memories/repo/` pointer file bootstrapped in Step 4.
- `../jira-workflow/SKILL.md` — the ticket start/finish/comment logic this
  skill chains into (Steps 1 and 9).
- `../git-branch-guard/SKILL.md` — the branch validation this skill chains
  into (Step 2).
