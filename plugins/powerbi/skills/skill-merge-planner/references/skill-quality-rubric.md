# Skill Quality Rubric (1–5 per dimension)

> **Not an official Anthropic-published framework.** No such numeric rubric exists publicly. This is a practical operationalization of Anthropic's qualitative Claude Skills authoring guidance — the same guidance mirrored locally in the `fabric-skill-creator` skill (progressive disclosure, degrees-of-freedom matching, conciseness, no duplication between SKILL.md and references, description/trigger quality, no extraneous files). Treat scores as directional, not authoritative.

Score each side of a compared skill pair 1–5 on each dimension below, then sum (max 35).

## Dimensions

### 1. Conciseness / context cost

Does the skill avoid paying token cost for information Claude doesn't need for the current task? The context window is shared by everything (system prompt, other skills' metadata, conversation history) — every unnecessary paragraph in a SKILL.md body is a tax paid on every triggering turn.

- **5** — SKILL.md body stays at the routing/workflow layer; all deep/topic-specific content lives in on-demand reference files with an explicit "context budget" callout.
- **3** — Mostly lean, but some implementation-adjacent detail bleeds into the body that belongs one level down.
- **1** — Body duplicates large chunks of reference-file content, or includes verbose restatement of things Claude already knows.

### 2. Progressive disclosure

Does the skill use the 3-level loading system correctly: metadata (~100 words, always loaded) → SKILL.md body (<500 lines, loaded on trigger) → bundled resources (loaded only when the body says to)?

- **5** — Clean split: frontmatter trigger is sufficient for routing; body is a workflow/router; every reference file has an explicit "when to read this" pointer.
- **3** — Reference table exists but body still carries implementation-level content, or reference "when to read" guidance is vague.
- **1** — No workflow selector or routing table; agent must infer which file to open; flat, undifferentiated reference list.

### 3. No duplication

Is information kept in exactly one place (SKILL.md body **or** a reference file, never both)? Does the skill have a clean ownership boundary vs. companion skills (no overlapping responsibility)?

- **5** — Explicit scope boundary stated ("this skill never edits X; use skill Y for that"); no content repeated between body and references.
- **3** — Boundary implied but not stated; some reference files overlap in subject matter with a companion skill.
- **1** — Skill duplicates or conflicts with a companion skill's job; phantom references to non-existent skills/plugins create ambiguity about where content actually lives.

### 4. Degrees-of-freedom matching

Is the amount of structure/specificity matched to how fragile or judgment-heavy the task is? Low freedom (exact scripts, few parameters) for fragile/must-follow-order tasks; high freedom (text guidance, heuristics) for genuinely open judgment calls — but not so high that a fragile task is left under-specified.

- **5** — Judgment-heavy steps have a decision table / scored-variant-selection mechanism with documented rationale; fragile/mechanical steps have an exact required sequence.
- **3** — Some structure exists but a fragile step is described only in prose, or a judgment-heavy step is over-specified into rigid rules that won't generalize.
- **1** — Flat prose throughout; no escalation/approval gates for high-risk changes; no variant/decision framework for genuinely ambiguous calls.

### 5. Description/trigger quality (frontmatter alone)

If Claude only ever saw the `name` + `description` fields (never the body), would it route correctly? Does the description state both *what* the skill does and *when* to use it, with concrete trigger phrases, and (ideally) explicit exclusions ("does NOT handle X — use Y")?

- **5** — Numbered capability list + trigger phrases + explicit "does NOT handle" redirect, all in the frontmatter description itself.
- **3** — Solid capability list and triggers, but the "does NOT handle" boundary only appears in the body (too late for routing).
- **1** — Vague description, or references dependencies/CLIs/plugins that don't actually exist — would misroute an agent.

### 6. No extraneous files / clutter

Does the skill folder contain only what's needed to do the job? No stray README.md/CHANGELOG.md/QUICK_REFERENCE.md inside the skill folder. Are reference files decomposed sensibly (one topic per file) rather than one giant file or many near-duplicate thin stubs?

- **5** — Every file in the skill folder is substantive and serves a distinct purpose; multi-part topics (e.g. archetypes) are purposefully decomposed one-file-per-variant.
- **3** — No clutter, but a couple of reference files are thin relative to their stated topic.
- **1** — Auxiliary documentation files that add token cost with no operational value; or a single monolithic reference file covering many unrelated topics.

### 7. Version hygiene (semver)

Does the skill have a `metadata.version` field, and is it valid semver that gets bumped when the skill changes materially?

- **5** — `metadata.version` present, valid semver (e.g. `0.2.0`), consistent with actual change history.
- **3** — `metadata.version` present but not obviously maintained (never bumped despite clear content changes).
- **1** — No version field at all, or a non-semver value (e.g. a date-like or unrelated counter).

## Using the Scores

- Sum all 7 dimensions per side (max 35). The higher score is the recommended architecture base **for that specific skill** — do not apply one repo's overall "reputation" to every skill pair; score independently each time.
- This rubric measures **authoring/architecture quality only**. It does NOT measure domain-content depth (e.g. how good the actual KPI-design guidance is). Content depth is a separate axis — capture it in the "cost-effective additions" analysis (Step 3 of the main workflow), not in this rubric.
- A skill can score low here while still containing content worth preserving — that's exactly the "graft the cost-effective parts, adopt the other side's architecture" pattern this rubric is designed to support.
