## Why

Two hygiene gaps need closing before the next merge: (1) the repo's existing
Claude Code compatibility conventions (`openspec/specs/repo-tooling/claude-code-packaging`)
need to be re-verified against the current state of every plugin — nothing in
the spec is changing, but compliance has never been checked after the most
recent skill/agent reconciliation commits — and (2) `plugins/devops` still
carries hardcoded references to a specific customer organization
(`bayviewasset` / `BAMDataServices`) inside shared setup assets, which leaks
customer-specific identifiers into a general-purpose, reusable skill.

## What Changes

- Run `tools/validate-skills.ps1` across all plugins and confirm every
  `SKILL.md` and agent file still validates clean; fix any file that fails
  frontmatter/structural checks so the tool reports zero warnings.
- Spot-check the `repo-tooling/claude-code-packaging` conventions that
  `validate-skills.ps1` does not mechanically check (per-plugin
  `.claude-plugin/plugin.json` manifests, dual-dialect agent pairs staying in
  sync, `.sh` siblings for Bash-based environments) and correct any drift
  found.
- Remove all `bayview`/`bayviewasset`/`BAMDataServices` references from
  `plugins/devops/skills/git-branch-guard/assets/setup_azure_cli.ps1` and
  `plugins/devops/skills/git-branch-guard/assets/azure-devops-cli-setup.md`,
  replacing them with neutral placeholder values so the skill's example
  commands don't imply a specific customer.
- No other `bayview` occurrences outside `plugins/devops` are touched (there
  are unrelated matches under `plugins/powerbi` sample assets/templates that
  are out of scope for this change).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None — this change verifies existing behavior against
`repo-tooling/claude-code-packaging` and removes customer-specific
placeholder text; it does not change what any requirement mandates. See
`.openspec.yaml` (`skip_specs: true`).

## Impact

- `tools/validation-reports/*` (regenerated, non-authored output)
- `plugins/devops/skills/git-branch-guard/assets/setup_azure_cli.ps1`
- `plugins/devops/skills/git-branch-guard/assets/azure-devops-cli-setup.md`
- Any plugin/skill/agent file found to violate existing Claude Code
  compatibility conventions during verification (scope determined during
  implementation; expected to be none, since the last validation run was
  clean)
