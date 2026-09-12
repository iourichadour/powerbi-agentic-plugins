## 1. Verify Claude Code compatibility

- [x] 1.1 Run `tools/validate-skills.ps1` and confirm the refreshed
      `tools/validation-reports/_summary.md` / `_summary.json` report 0
      warnings across all `SKILL.md` and agent files
- [x] 1.2 Spot-check the conventions `validate-skills.ps1` does not
      mechanically check against `openspec/specs/repo-tooling/claude-code-packaging`:
      confirm every `plugins/<plugin>/.claude-plugin/plugin.json` exists with
      `name`/`description`/`version`; confirm each `<agent>.md` /
      `<agent>.agent.md` dual-dialect pair still has equivalent body content;
      confirm every Bash-required `.ps1` helper referenced by agent/skill
      instructions has a `.sh` sibling
- [x] 1.3 Fix any drift found in 1.1 or 1.2 and re-run
      `tools/validate-skills.ps1` until it reports 0 warnings

## 2. Remove bayview references from devops

- [x] 2.1 Replace the `bayviewasset` org URL and `BAMDataServices` project
      name in `plugins/devops/skills/git-branch-guard/assets/setup_azure_cli.ps1`
      with neutral placeholder values, and verify with
      `grep -ri bayview plugins/devops` returning no matches
- [x] 2.2 Replace the `bayviewasset` / `BAMDataServices` references in
      `plugins/devops/skills/git-branch-guard/assets/azure-devops-cli-setup.md`
      (command example, prose, and sample output) with the same neutral
      placeholder values used in 2.1, and verify with
      `grep -ri bayview plugins/devops` returning no matches
- [x] 2.3 Confirm no other file under `plugins/devops` references bayview by
      re-running `grep -ril bayview plugins/devops`

## 3. Final check and handoff

- [x] 3.1 Re-run `tools/validate-skills.ps1` one more time after the devops
      edits and confirm 0 warnings (edits in section 2 touch only asset
      scripts/docs, not frontmatter, so the count should be unchanged)
- [x] 3.2 Run `git status` / `git diff` to review the full changeset, then
      pause and present it to the user for approval before `git commit` or
      `git push`
