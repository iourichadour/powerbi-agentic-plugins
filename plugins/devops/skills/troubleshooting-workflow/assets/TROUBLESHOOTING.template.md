# TROUBLESHOOTING.md

Living log of investigated issues in this repo, written so an agent can resume
or reproduce an investigation without repeating discovery work from scratch.

## How to use this file

- One `##` section per Jira ticket or issue.
- Keep entries factual: symptom, data flow traced, root-cause candidates with
  file/line evidence, environment notes, and current status. Do not mark an
  entry resolved unless the root cause was confirmed against live data.
- Update the entry in place as new evidence is gathered instead of duplicating it.
- Prefer linking to exact files/paths over re-describing pipeline logic.

## Standard troubleshooting environment

- Fill in the repo's known-good live-query connection here once one is confirmed.
- Prefer the working connection that was already proved in this repo over
  rediscovering a new one every session.
- Record the data platform, workspace/project, server/database or equivalent,
  and any non-obvious auth/profile details needed for a future agent to resume.
- If the repo has multiple environments, note which one should be used first
  for read-only troubleshooting.

---

## Example issue — replace with real tickets

**Status:** Investigation in progress.
**Branch:** `feature/ABC-123-short-description`
**Jira:** https://example.atlassian.net/browse/ABC-123

### Symptom
Describe the user-visible problem exactly as reported.

### Data flow traced
List the end-to-end flow, with file and component names in order.

### Root-cause candidates (ranked by evidence strength)

1. **Candidate one**
   [path/to/file.ext](path/to/file.ext)
   Explain why this is plausible and what evidence points here.

2. **Candidate two**
   [path/to/other-file.ext](path/to/other-file.ext)
   Explain the alternate hypothesis and what still needs confirmation.

### Live-query evidence

- Query or observation 1
- Query or observation 2

### Current status

Summarize whether the root cause is confirmed, ruled out, or still pending.

### Environment / connection notes

- Document the working connection details that future troubleshooting sessions
  should reuse.

### Actions taken this session

- Note the durable actions completed during the session.
