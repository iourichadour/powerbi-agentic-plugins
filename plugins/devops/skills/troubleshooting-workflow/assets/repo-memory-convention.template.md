# /memories/repo/troubleshooting-log-convention.md

This file points future troubleshooting sessions to the repo's living log and
captures durable conventions that are cheaper to remember than to rediscover.

## Purpose

- Check this file first when starting a new troubleshooting session in this repo.
- Reuse any working environment, workspace, profile, or connection details
  documented here before trying to rediscover them.
- Update this file only when a new troubleshooting convention is confirmed and
  should be reused by later sessions.

## What to store here

- Preferred live-query environment for this repo.
- Known-good tool names or profiles for read-only troubleshooting.
- Any recurring gotchas that repeatedly slow down investigations.
- Any repo-specific rule for whether DEV, TEST, or another environment should
  be queried first.

## Pointer back to the living log

- See `TROUBLESHOOTING.md` for the detailed investigation history.
- Keep that file as the canonical ticket-by-ticket source of truth.

## Update rule

- When a new DEV/TEST-style environment fact is confirmed, append it here so
  future sessions can start with the proven path instead of guessing.
