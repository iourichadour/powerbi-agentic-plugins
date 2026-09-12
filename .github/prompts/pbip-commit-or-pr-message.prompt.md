---
description: "Run the PBIP change-summary reviewer against a ref range and turn its deterministic diff output into a Jira-prefixed git commit message or a PR description."
agent: "agent"
argument-hint: "commit | pr [old-ref] [new-ref]"
---

Generate a **commit message** or **PR description** for PBIP (Power BI Project) changes,
grounded in the deterministic diff produced by
[`commit_diff_summary.ps1`](../scripts/pbip-pr-summary/commit_diff_summary.ps1)
(POSIX: [`commit_diff_summary.sh`](../scripts/pbip-pr-summary/commit_diff_summary.sh)), which
wraps [`pbip_change_reviewer.py`](../scripts/pbip-pr-summary/pbip_change_reviewer.py). That
script is the **source of facts** — never invent changes it didn't report, and never paste its
raw bullet-list output verbatim as the deliverable; it's an input to synthesize from, not the
final message.

## 1. Determine mode and ref range

Read the user's request (or the `argument-hint` args) to pick a mode:

- **`commit`** — summarizing the most recent commit(s) on the current branch. Default range is
  `Old=HEAD~1 New=HEAD` (the script's own default). If the user has uncommitted changes, tell
  them to commit first — this tool diffs committed refs via `git worktree add`, not the working
  tree.
- **`pr`** — summarizing an entire feature branch against its base for a pull/merge request.
  Determine `New` = current branch (`git rev-parse --abbrev-ref HEAD`) and `Old` = the base
  branch. Ask the user if unclear; common bases in this repo are `DEV` and `main`. Use
  `git merge-base` to sanity-check the range before running the script.

## 2. Run the reviewer

```powershell
.\github\scripts\pbip-pr-summary\commit_diff_summary.ps1 -Old <old-ref> -New <new-ref>
```

Do **not** pass `-KeepWorktrees` — let the script clean up its temporary worktrees automatically.
Capture the printed markdown (TOC + per-report `Visual Changes`/`Semantic Model Changes`
sections + `Other Changes`).

## 3. Extract the Jira ticket ID

Parse the current branch name for a ticket ID (e.g. `feature/FIN-1783-...` → `FIN-1783`,
`bugfix/FIN-1757-...` → `FIN-1757`). If found, prefix the generated message with it, per this
repo's commit convention. If no ticket ID is identifiable, omit the prefix rather than guessing.

## 4. Synthesize the message (do not dump raw output)
Read the reviewer's Markdown and preserve its information architecture in the deliverable.
The reviewer output is the source of facts, while the generated text is a readable synthesis.
Do not flatten all changes into a short cross-report list.

Keep the following structure and ordering:

```markdown
# PBIP Change Summary
## Table of Contents
## Report 1: <Report Name>
### Visual Changes
#### Page: <Page Name>
##### Visual: <Visual Name>
- <summarized visual change>
### Semantic Model Changes
- <detailed model change>
## Report 2: <Report Name>
...
## Other Changes
- <change>
```

Use the exact report numbers and report names from the reviewer output, including Report 2
and any report whose changes are summarized. Preserve the report order and keep the `Other
Changes` section at the end. If the reviewer does not provide enough information to create a
page or visual heading, keep the change under the relevant section without inventing a name.
Keep the Table of Contents aligned with the headings in the generated document.

Under `Visual Changes`, group entries by page and then by visual whenever those names are
available. Summarize related property-path bullets into a detailed prose bullet that states
the affected page, visual, field/filter/bookmark, and the before/after behavior. Include
meaningful visual changes such as added or removed pages, visual types, fields, measures,
filters, bookmarks, sort order, and trend or KPI configurations. Combine purely mechanical
position, sizing, z-order, and formatting changes into a concise bullet unless they are the
only changes for that visual. Do not repeat every low-level property path verbatim.

Give `Semantic Model Changes` priority over cosmetic visual changes. Preserve the exact names
of model objects and describe model changes in detail, grouped where possible by tables,
columns, measures, relationships, hierarchies, partitions, calculated tables, and
expressions. For each change, state whether the object was added, removed, renamed, rebound,
or modified, and include relevant source/target names, formula changes, and relationship or
dependency implications reported by the reviewer. Explicitly call out table or field
rebinding that affects report behavior. Do not infer business meaning, data lineage, or
validation results that the reviewer did not report.

Do not paste the raw bullet-list output verbatim. Synthesize it into complete, precise prose,
but retain enough detail that a reviewer can understand the affected reports, pages, visuals,
and semantic model without reopening the raw diff.

**`commit` mode** — produce:
- **Subject** (≤72 chars): `<TICKET>: <imperative summary of the dominant change>`
- **Body**: retain the full report/page/visual/semantic-model structure above. Use a short
  prose summary for each affected report, followed by the detailed changes grouped under
  `Visual Changes` and `Semantic Model Changes`. Give semantic model changes more detail than
  cosmetic visual changes. Skip purely cosmetic entries (visual moves/resizes, diagram layout,
  auto date tables) unless they are the only changes present.

**`pr` mode** — produce a title + Markdown body:
```markdown
PBIP Change Summary

## Table of Contents

## <TICKET>: <Title>

## Summary
<2-4 sentences: what this PR does and why>

## Report 1: <Report Name>
### Visual Changes
#### Page: <Page Name>
##### Visual: <Visual Name>
- <detailed, condensed prose bullet — not a raw diff line>
### Semantic Model Changes
- <detailed semantic model change>

## Report 2: <Report Name>
...

## Other Changes
- <change>

## Validation
- [ ] Desktop regression checked for affected report(s)
- [ ] Before/after KPI comparison recorded (if measures changed)
```
Keep every report section from the reviewer output, including reports with changes that are
mostly cosmetic; summarize cosmetic-only sections briefly instead of silently dropping them.
Use `Other Changes` only for changes the reviewer placed outside a report. The PR body must
retain detailed semantic model changes even when the visual changes are numerous.

## 5. Present, don't auto-commit

Show the drafted message in a fenced code block. Only run `git commit -m "..."` (or update a PR
description via the ADO/GitHub tooling) if the user explicitly asks you to — drafting is the
default behavior.
