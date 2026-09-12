## Why

Two agent-instruction documents in this repo are inconsistent with the repo's actual structure, and one agent lacks an explicit rule to validate a task against its acceptance criteria before marking it done:

1. `AGENTS.md`'s "Update Check" note tells the agent to compare a local `package.json` against `https://github.com/YuriChadour/powerbi-agentic-plugins`'s remote `package.json`, but this repo has no root `package.json` at all (or anywhere in the tree) — version is tracked in `.claude-plugin/marketplace.json` (`metadata.version` and per-plugin `version` fields). Following the current instruction literally causes the agent to read a nonexistent file.
2. `plugins/powerbi/skills/check-updates/SKILL.md` still documents the older `skills-for-fabric` marketplace's manifest layout (`.github/plugin/plugin.json` for a Copilot CLI plugin install, or root `package.json` for a manual clone, both pointed at `microsoft/skills-for-fabric`). This repo is `YuriChadour/powerbi-agentic-plugins` and uses `.claude-plugin/marketplace.json` plus per-plugin `plugin.json`/marketplace entries, so the skill's Step 1-3 guidance and Reference links do not match where this repo actually stores its version and repository metadata.
3. `plugins/powerbi/agents/powerbi-developer.agent.md` describes a multi-task spec execution loop ("Execute tasks", "mark it as done in the plan/spec") but has no explicit instruction to check a task's output against its own acceptance criteria before marking it complete, leaving room for tasks to be marked done without verification.

## What Changes

- Update `AGENTS.md`'s Update Check note to reference this repo's actual version manifest (`.claude-plugin/marketplace.json`) instead of a nonexistent root `package.json`.
- Rewrite `plugins/powerbi/skills/check-updates/SKILL.md` Steps 1-3 (local version, repository owner/name, latest-release fetch) and the Reference section to target `.claude-plugin/marketplace.json` (repo-level `metadata.version` and/or per-plugin `version`) and the `YuriChadour/powerbi-agentic-plugins` repository, removing the obsolete `skills-for-fabric`/`microsoft/skills-for-fabric`/dual-manifest-layout guidance that no longer applies to this repo.
- Add an explicit completion rule to `plugins/powerbi/agents/powerbi-developer.agent.md`'s "Implementing a spec" section: before marking any task done, the agent must validate its output against that task's stated acceptance criteria (or the spec's relevant requirement/scenario) and only mark it done if it passes; otherwise it must report the gap instead of marking it done.

## Capabilities

### New Capabilities
- `powerbi/update-check-docs`: Accuracy requirements for the repo-level and skill-level update-check instructions — they must reference version/repository metadata that actually exists in this repo.
- `powerbi/powerbi-developer-agent-completion`: Requirement that the `powerbi-developer` agent validate each task's output against its acceptance criteria before marking it complete during spec implementation.

### Modified Capabilities
(none — both capabilities above are newly documented; no existing `openspec/specs/` capability currently covers update-check accuracy or this agent's completion rule)

## Impact

- Affected files: `AGENTS.md`, `plugins/powerbi/skills/check-updates/SKILL.md`, `plugins/powerbi/agents/powerbi-developer.agent.md`.
- No code, build, or runtime systems are affected — this is an agent-instruction/documentation correctness change.
- No breaking changes to any published skill/agent interface; behavior only becomes more accurate (correct manifest paths) and more rigorous (explicit completion gate).
