# /memories/repo/MEMORY.md

This pointer references the repository's durable memory file. It must not
duplicate ticket status, active branches, next steps, or a second memory
source.

## Purpose

- Check `MEMORY.md` first when starting a new session in this repo.
- Reuse durable project conventions documented there before trying to
  rediscover them.
- Update `MEMORY.md` only when a new vendor-neutral fact is confirmed and
  should be reused by later sessions.

## What belongs in `MEMORY.md`

- Project architecture and durable conventions.
- Known limitations and recurring gotchas that apply beyond one ticket.
- Record roles and recovery rules that a new harness must understand.

## Pointer back to the durable memory

- See `MEMORY.md` for the canonical durable project facts.

## Update rule

- When a durable, vendor-neutral project fact is confirmed, update `MEMORY.md`.
