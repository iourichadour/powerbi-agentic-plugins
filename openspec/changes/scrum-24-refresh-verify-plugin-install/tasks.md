## 1. Work-on trigger and guard handoff (repo edits)

- [x] 1.1 Add "work on <KEY>" (case-insensitive, optional leading "I want to" / "let's" / "I'm going to") to the start-ticket trigger list in `plugins/devops/skills/jira-workflow/SKILL.md` Step 2; verify the phrase matches and the no-key case asks the user
- [x] 1.2 Add the same phrase to the start-ticket section of `plugins/devops/agents/devops.md`, `devops.agent.md`, and the Codex adapter `devops.toml`; verify all three and `jira-workflow` SKILL.md list identical phrases
- [x] 1.3 Make the guard handoff explicit in `jira-workflow` Step 2.6 and `git-branch-guard` SKILL.md: no branch creation in the trigger handler, no code change until the guard passes; verify wording matches spec `devops/jira-work-trigger`

- [x] 1.4 Replace the stale `check_git_branch_guard.txt` reference in `.github/prompts/git-branch-guard.md` with the `.ps1` and `.sh` scripts; verified the repo `.ps1` runs and passes on the current branch
- [x] 1.5 Make the decided Jira behavior explicit in `jira-workflow` SKILL.md Step 2 and the three devops agent dialects: "work on <KEY>" assigns and moves the named ticket to In Progress without asking; comments and writes on other tickets still ask first; verify wording matches spec "Start-ticket flow assigns and starts the named ticket without asking"

## 2. PR host detection (repo edits)

- [x] 2.1 Add origin-host detection from `git remote get-url origin` to `plugins/devops/skills/git-branch-guard/assets/create_pr.ps1` and `assets/create_pr.sh`; verify `github.com` and `dev.azure.com` URLs classify correctly and other hosts report unsupported
- [x] 2.2 Route `github.com` to `gh pr create` with the confirmed title, body, and target branch, after checking `gh` is installed and authenticated and reporting the specific missing prerequisite otherwise; verify on a GitHub remote with and without `az` installed Done 2026-10-11: verified with stubbed `gh`/`az` in bash and PowerShell, including a run with no `az` on PATH; the live `gh pr create` check is task 6.3
- [x] 2.3 Keep `dev.azure.com` on `az repos pr create` with its existing prerequisite checks (`azure-devops` extension, login, org/project); verify on an Azure DevOps remote Done 2026-10-11: verified with stubbed CLIs; the live `az repos pr create` check is task 6.3
- [x] 2.4 Update the SKILL.md dependency section to describe both paths and the host-specific prerequisites; verify it matches the scripts

## 3. Plugin install refresh (needs approval: `~/.claude`)

- [x] 3.0 Plan the refresh around `setup-claude-plugins.ps1` (registers or refreshes the marketplace, installs all or one plugin); show the user the exact command and what it will change in `~/.claude` before running it Done 2026-10-11: ran `setup-claude-plugins.ps1 -PluginName <p> -Force -SkipDesktopBridge` for powerbi, fabric, devops with the user's approval; `-SkipDesktopBridge` avoided the global npm install of the Desktop Bridge CLI
- [x] 3.1 Compare installed powerbi (0.3.0), fabric (0.2.0, same version number but different content), devops (0.1.0), and skill-creator with the repo marketplace.json; compare content as well as version numbers, because fabric matches by number but not by content; list missing skills, `common/` docs, and scripts; verify the list before any change Done 2026-10-11: compared version and content per plugin against the cache
- [x] 3.2 Install missing powerbi skills (dax-test-framework, dax-unit-testing, paginated-report-authoring); verify every repo powerbi skill is in the cache Done 2026-10-11: powerbi 0.5.0 cache has all 14 repo skills (dax-test-framework, dax-unit-testing, paginated-report-authoring added) and all 11 agent files
- [x] 3.3 Install the 12 missing fabric skills and `common/` docs; decide whether to restore the FabricIQ HTTP MCP server (MCP config change, needs approval); verify skill list matches the repo Done 2026-10-11: fabric cache now has all 11 repo skills, 4 agent files, and `common/`. The plugin's `.mcp.json` came with it and defines `fabric-mcp-server` (npx @microsoft/fabric-mcp) and `FabricIQ` (HTTP). FabricIQ's auth helper runs `az account get-access-token`, so it will fail to authenticate while `az` is not installed
- [x] 3.4 Install the devops troubleshooting-workflow skill and .ps1/.sh scripts; verify devops version reads 0.2.0 Done 2026-10-11: devops 0.2.0 cache has the troubleshooting-workflow skill, `.ps1`/`.sh` scripts, and all 3 agent files
- [x] 3.5 Replace the cached devops `git-branch-guard` script `check_git_branch_guard.txt` with the repo's `check_git_branch_guard.ps1` and `.sh` (version 0.2.0); verify the cache has no `.txt` copy and `SKILL.md` references resolve Done 2026-10-11: active devops 0.2.0 has `check_git_branch_guard.ps1` and `.sh`; the old 0.1.0 folder (with the `.txt`) is still on disk but inactive
- [x] 3.6 Decide on installing spec-lifecycle (0.1.0); if installed, enable it at user scope; record the decision in this file. Decision (2026-10-11): installed and enabled at user scope by the user's request, using `setup-claude-plugins.ps1 -PluginName spec-lifecycle`; `claude plugin list` shows `spec-lifecycle@powerbi-agentic-plugins` 0.1.0 enabled. The run also refreshed the local marketplace registration from the repo; no other plugin was changed (powerbi 0.3.0 and devops 0.1.0 remain stale). Restart Claude Code or run `/plugin` to load it
- [x] 3.7 Confirm installed versions match the repo `marketplace.json` (powerbi 0.5.0, fabric 0.2.0, devops 0.2.0, skill-creator 1.0.0) and every repo skill folder is present in the cache; record the check result Done 2026-10-11: `claude plugin list` shows powerbi 0.5.0, fabric 0.2.0, devops 0.2.0, skill-creator 1.0.0, spec-lifecycle 0.1.0, all enabled; every repo skill and agent file is present in the matching cache folder. The stale `powerbi/0.3.0` and `devops/0.1.0` cache folders were sent to the Recycle Bin on 2026-10-11 with the user's approval; nothing in `installed_plugins.json` pointed at them

## 4. Agent updates

- [x] 4.1 Remove the UTF-8 byte order mark from `plugins/powerbi/agents/pql-tester.md`; verify the first three bytes are `---` and the body is unchanged
- [x] 4.2 Add a leading-byte (BOM) check for agent Markdown files to `tools/validate-skills.ps1`; verify it fails on a copy of `pql-tester.md` with the mark and passes on the fixed file Done 2026-10-11: validator now exits non-zero on a byte order mark; confirmed it failed on the original `pql-tester.md`
- [x] 4.2a Add a parity check to `tools/validate-skills.ps1` that compares the start-ticket trigger phrases in `devops.md`, `devops.agent.md`, `devops.toml`, and `jira-workflow` SKILL.md; also assert that "work on <KEY>" is present in all four; verify it fails when one dialect or the skill omits any phrase (including "work on <KEY>") and passes when all match (spec: "Trigger phrases are identical across agent dialects"); required for this change Done 2026-10-11: validator fails when `work on <KEY>` or any phrase is missing from a dialect or the skill (tested on a copy) and passes on the real files
- [x] 4.3 Run `tools/validate-skills.ps1` over `plugins/**` and record that every other agent file passes Done 2026-10-11: `pbip-validator`, `powerbi-*`, devops, and Fabric agents report no byte order mark; 2 pre-existing warnings remain on `FabricDataEngineer` and `FabricMigrationEngineer` (see 4.6)
- [ ] 4.4 After the refresh, check in a fresh session that `pql-tester` is in the agent list; if not, check the `tools:` MCP server name (`mcp__powerbi-modeling-mcp`) next and document the failure with evidence
- [x] 4.5 Confirm `powerbi/pql-tester-agent` behavior is unchanged (operating modes); verify no spec delta is needed for it
- [ ] 4.6 Record the Claude-format Fabric agent decision. If approved, add `FabricDataEngineer.md` and `FabricMigrationEngineer.md` with bodies equivalent to the `.agent.md` files and keep the one-to-one `.toml` pairing; if declined, document the omission in the fabric plugin README
- [x] 4.7 Confirm the `az` install is not required on this machine for GitHub repos; document that `az` is needed only for Azure DevOps repos (see 5.1)

## 4a. Approval gates

- [ ] 4a.1 Before any `~/.claude` change, `az` install, MCP config change, Jira comment or transition on a ticket other than SCRUM-24, push, or PR: ask the user and wait for an explicit yes

## 5. Documentation

- [x] 5.1 Document in devops SKILL.md and DEVELOPER_SETUP.md that `az` is needed only for Azure DevOps repos; verify the note matches the PR-host behavior
- [x] 5.2 Confirm `gh` is authenticated for the GitHub path (`gh auth status`, account `iourichadour`); record the output in the change Result 2026-10-11: `gh auth status` shows logged in to github.com as `iourichadour` (keyring, https)
- [x] 5.3 Check `az --version` in PowerShell and record whether `az` is on PATH; no install happens without approval Result 2026-10-11: `az` was not on PATH in Git Bash or PowerShell. Then installed at the user's request (see 5.4)

- [x] 5.4 Installed Azure CLI 2.91.0 and the azure-devops extension on 2026-10-11 at the user's request, using `plugins/devops/skills/git-branch-guard/assets/setup_azure_cli.ps1 -SkipDefaults` (Microsoft zip, no admin; installed to `%LOCALAPPDATA%\GitHubCopilotCLI\az`, user PATH updated, default organization not set). Not logged in: the user runs `az login` interactively; open a new terminal for PATH

## 6. Validation

- [ ] 6.1 In a fresh Claude Code session outside the repo folder, say "work on SCRUM-24"; verify `jira-workflow` triggers, the ticket is fetched, and `git-branch-guard` runs before any code change
- [ ] 6.2 In a fresh session, confirm "work on SCRUM-24" assigns and moves the ticket to In Progress without asking, and that any comment, or any write on another ticket, asks first. This intentionally differs from the ticket's test-plan wording ("asks before any transition"); the user decided on 2026-10-11
- [ ] 6.2b Run `tools/validate-skills.ps1` and record that the trigger-phrase parity check passes on the final files
- [ ] 6.2a Confirm `git-branch-guard` checks for a `feature/` or `bugfix/` branch containing the Jira key, using the `.ps1` (Windows) or `.sh` (Bash) script
- [ ] 6.3 On a GitHub repo, confirm PR creation uses `gh pr create`; on an Azure DevOps repo, confirm `az repos pr create`
- [ ] 6.3a Verify every SCRUM-24 acceptance criterion in proposal.md and record the result per criterion: versions match, every repo skill present, spec-lifecycle decision, pql-tester outcome, fabric agent decision, `az` documented, PR creation for both hosts, fresh session outside the repo folder
- [ ] 6.4 Run `openspec validate scrum-24-refresh-verify-plugin-install` and record the result
