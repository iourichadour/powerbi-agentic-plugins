## Why

This repo (`powerbi-agentic-plugins-main`) is a plain file snapshot (no `.git`) that
has become the source of truth for OpenSpec tooling, the devops PR-creation/branch-reuse
work, and the full `dax-test-framework`/`dax-unit-testing` skills — none of which exist
in the actual git clone at `C:\Development\powerbi-agentic-plugins`
(`feature/claude-code-setup` branch). Meanwhile that git clone independently grew its
own "Claude Code compatibility" packaging layer (per-plugin `.claude-plugin/plugin.json`
manifests, a `.sh`-sibling-script convention, `setup-claude-plugins.ps1`, a skill/agent
validator under `tools/`, and `skill-eval-reports/`) that does not exist here. Without a
tracked reconciliation, either side's unique work risks being silently lost the next time
one repo is copied over the other.

## What Changes

- Bring the git repo (`C:\Development\powerbi-agentic-plugins`) up to date with this
  repo's content: full OpenSpec scaffolding (`openspec/`, `.agents/skills/openspec-*`,
  `.claude/skills/openspec-*`, `.claude/commands/opsx/*`, `.github/skills/openspec-*`,
  `.github/prompts/opsx-*`), the newer `devops` agent/skill (PR creation + branch reuse),
  the `dax-test-framework` and `dax-unit-testing` skills, `powerbi-report-authoring`
  reference-scan scripts, the `troubleshooting-workflow` skill, the new `spec-lifecycle`
  plugin, and the current `.claude-plugin/marketplace.json`.
- Re-apply the git repo's unique "Claude Code packaging layer" on top of that updated
  content instead of discarding it: per-plugin `.claude-plugin/plugin.json` manifests,
  the `.sh`-sibling-script convention for `devops` helper scripts (a `.sh` script next
  to each `.ps1` for Bash-based agent environments), `setup-claude-plugins.ps1`,
  `tools/validate-skills.ps1` (+ `tools/validation-reports/`), and `skill-eval-reports/`.
- Formalize this packaging layer as a documented, ongoing repo convention (a spec) so
  future syncs between the two repos don't have to be rediscovered by diffing file trees.
- Discard clone-local noise found in the git repo: `bash.exe.stackdump` and
  `.claude/settings.local.json` (machine-local Claude Code permission cache).
- Establish which of the two locations (`powerbi-agentic-plugins-main` file tree vs. the
  `C:\Development\powerbi-agentic-plugins` git clone) is the ongoing source of truth for
  future work, to prevent this divergence from recurring.

## Capabilities

### New Capabilities
- `repo-tooling/claude-code-packaging`: defines the per-plugin manifest, portable-script,
  installer, and validation/eval-report conventions that must be present and kept in sync
  across both repo locations for Claude Code plugin installation to work.

### Modified Capabilities
- (none — no existing spec's requirements change; the devops PR-creation/branch-reuse and
  dax-test-framework/dax-unit-testing specs already describe their own behavior and are
  only being *copied* into the other location, not altered)

## Impact

- Affected paths (in the git clone `C:\Development\powerbi-agentic-plugins`): `openspec/`,
  `.agents/`, `.claude/`, `.github/`, `plugins/devops/**`, `plugins/powerbi/skills/dax-test-framework/**`,
  `plugins/powerbi/skills/dax-unit-testing/**`, `plugins/powerbi/skills/powerbi-report-authoring/scripts/**`,
  `plugins/spec-lifecycle/**`, `.claude-plugin/marketplace.json`, root docs (`RELEASE_NOTES.md`).
- Affected paths (in this file tree `powerbi-agentic-plugins-main`, to receive the packaging layer back):
  `plugins/*/.claude-plugin/plugin.json`, `plugins/devops/agents/devops.agent.md` (Copilot
  dialect, added alongside the existing `devops.md` Claude Code dialect — not replacing it) +
  `.sh` sibling script copies, `setup-claude-plugins.ps1`, `tools/validate-skills.ps1`,
  `tools/validation-reports/`, `skill-eval-reports/`.
- No production code, APIs, or external dependencies are affected — this is purely
  repository content reconciliation and dev-tooling convention documentation.
- Cross-repo operation: edits span two separate filesystem locations. Implementation
  will need explicit approval to write outside this planning repo's root.
