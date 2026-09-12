## 1. Bring the git clone up to date with this file tree's unique content

- [x] 1.1 Copy `openspec/` (config.yaml, `specs/`, `changes/` including archived changes) from this file tree into the git clone, and verify `openspec status` runs cleanly in the git clone afterward
- [x] 1.2 Copy `.agents/skills/openspec-*`, `.claude/skills/openspec-*`, `.claude/commands/opsx/*`, `.github/skills/openspec-*`, and `.github/prompts/opsx-*.prompt.md` into the git clone, and verify each file exists at the matching path
- [x] 1.3 Copy the newer `plugins/devops/agents/devops.agent.md` and its supporting assets (`apply_standard_branch_policies.ps1`, `check_git_branch_guard.ps1`, `git-branch-guard/assets/**` including `create_pr.ps1` and `setup_azure_cli.ps1`) into the git clone
- [x] 1.4 Update the git clone's `plugins/devops/agents/devops.md` in place with the newer PR-creation/branch-reuse orchestration content (do not delete it — it is the Claude Code dialect counterpart to `devops.agent.md`, kept side by side per convention), delete the now-superseded `apply_standard_branch_policies.txt` and `check_git_branch_guard.txt` (replaced by the `.ps1`/`.sh` sibling pairs from 1.3/2.2), and verify both `devops.md` and `devops.agent.md` exist with equivalent behavioral content
- [x] 1.5 Copy `plugins/devops/skills/troubleshooting-workflow/` into the git clone
- [x] 1.6 Copy `plugins/powerbi/skills/dax-test-framework/` and `plugins/powerbi/skills/dax-unit-testing/` (including `scripts/`, `tests/`, `assets/`, `references/`, `evals/`, `pyproject.toml`, `uv.lock`) into the git clone, and verify the directory trees match this file tree's byte-for-byte
- [x] 1.7 Copy `plugins/powerbi/skills/powerbi-report-authoring/scripts/report_reference_scan.ps1`, `report_reference_scan.py`, and `scripts/tests/test_report_reference_scan.py` into the git clone
- [x] 1.8 Copy `plugins/spec-lifecycle/` (new plugin) into the git clone
- [x] 1.9 Copy `.claude-plugin/marketplace.json` and root `RELEASE_NOTES.md` into the git clone, and verify the marketplace JSON is valid (parses with no errors) and lists `spec-lifecycle`
- [x] 1.10 Copy `plugins/powerbi/agents/*.agent.md` (Copilot dialect) into the git clone alongside its existing `plugins/powerbi/agents/*.md` (Claude Code dialect) for `powerbi-architect`, `powerbi-developer`, and `pql-tester` — do not delete or replace the `.md` files — after diffing content to confirm which dialect has the more current behavioral content and porting any missing updates into the other; document the diff result in the PR/commit description

## 2. Re-apply the Claude Code packaging layer on top of the updated content (both locations)

- [x] 2.1 In the git clone, regenerate/update `.claude-plugin/plugin.json` manifests for any plugin whose metadata changed as a result of section 1 (e.g. `devops`, and new `spec-lifecycle`, `dax-test-framework`, `dax-unit-testing` if they are to be individually installable), and verify each manifest has `name`, `description`, and `version`
- [x] 2.2 In the git clone, create `.sh` sibling scripts alongside the newly-copied devops scripts (`apply_standard_branch_policies.ps1`, `check_git_branch_guard.ps1`) with equivalent behavior, and verify `pwsh -File <script>.ps1` (PowerShell 7) and `bash <script>.sh` (Git Bash) both run successfully and produce equivalent results
- [x] 2.3 Copy `setup-claude-plugins.ps1` from the git clone into this file tree, and verify it runs against this file tree's `.claude-plugin/marketplace.json`
- [x] 2.4 Copy `tools/validate-skills.ps1` from the git clone into this file tree, run it, and verify a fresh `tools/validation-reports/_summary.md` and `_summary.json` are produced covering this file tree's plugins
- [x] 2.5 Copy `skill-eval-reports/run-skill-eval.ps1` from the git clone into this file tree, run it, and verify a fresh `skill-eval-reports/reports/SUMMARY.md` is produced
- [x] 2.6 Re-run `tools/validate-skills.ps1` and `skill-eval-reports/run-skill-eval.ps1` in the git clone against its now-updated plugin content, and verify the reports reflect the newly-copied skills/agents (e.g. `dax-test-framework`, `dax-unit-testing`, `troubleshooting-workflow`) with no unexpected failures

## 3. Remove clone-local noise

- [x] 3.1 Delete `bash.exe.stackdump` from the git clone and verify it no longer exists
- [x] 3.2 Delete `.claude/settings.local.json` from the git clone (and confirm it is covered by `.gitignore` or an equivalent local-only exclusion going forward) and verify it no longer exists

## 4. Verify convergence and hand off for commit

- [x] 4.1 Re-run the file-list diff between this file tree and the git clone (same method used during the initial review) and verify the only remaining differences are expected in-flight/local artifacts (e.g. `.git/`), with no unexplained unique files on either side — verified: the only remaining differences are `plans/*.md` working-note files unique to each location (not in this change's declared scope), no unexplained differences in `openspec/`, `.agents/`, `.claude/`, `.github/`, `plugins/`, `.claude-plugin/marketplace.json`, `tools/`, or `skill-eval-reports/`
- [x] 4.2 Present a summary of all copied/deleted files to the user for review before any `git add`/`git commit` is executed in the clone
- [x] 4.3 On explicit user approval, commit the reconciliation in the git clone with a descriptive message referencing this change, and verify `git status` is clean afterward — committed as `76d6ed4` on `feature/SCRUM-2-skill-merge` and pushed to `origin`
