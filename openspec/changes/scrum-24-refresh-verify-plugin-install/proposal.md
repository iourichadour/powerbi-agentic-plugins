## Why

Saying "work on SCRUM-24" in Claude Code does not reliably start the Jira workflow. The documented start-ticket trigger list does not include the bare "work on <KEY>" phrasing, so the `jira-workflow` skill and then `git-branch-guard` may not run. The local plugin install is also stale and incomplete, and the devops PR path only works for Azure DevOps even though this repo's origin is GitHub. (Jira SCRUM-24.)

## What Changes

- Add "work on <KEY>" (and its natural variants) to the start-ticket trigger list, so it routes to `jira-workflow` first, then `git-branch-guard` before any branch is created or code is changed.
- Require that branch creation or switching for a ticket goes through `git-branch-guard`, and that no code change starts until the guard passes.
- Add GitHub PR creation to the devops plugin: `gh pr create` for `github.com` remotes, and the existing `az repos pr create` path for `dev.azure.com` remotes.
- Refresh the installed plugins under `~/.claude` to match the repo's `marketplace.json` versions (powerbi 0.5.0, fabric 0.2.0, devops 0.2.0, skill-creator 1.0.0), including the missing skills, `common/` docs, and devops scripts.
- Decide on installing `spec-lifecycle`, diagnose why `pql-tester` is absent from the agent list, and record the decision on Claude-format fabric agents.
- Document that `az` is needed only for Azure DevOps repositories.
- Keep "work on <KEY>" assigning the ticket and moving it to In Progress automatically (decided by the user); comments and writes on other tickets still ask first. See task 1.5.
- Agent updates:
  - Keep the devops persona agent consistent across its dialects: the new trigger phrase goes into `devops.md` (Claude Code), `devops.agent.md` (Copilot), and `devops.toml` (Codex) in the same edit, as `repo-tooling/claude-code-packaging` and `codex-plugin-compatibility` require.
  - Fix `pql-tester` loading: `plugins/powerbi/agents/pql-tester.md` is the only agent Markdown file that starts with a UTF-8 byte order mark (`EF BB BF`) before the frontmatter, which is the likely reason it is missing from the session agent list. Remove the mark and make `tools/validate-skills.ps1` fail on it.
  - Decide on Claude-format fabric agents. `FabricDataEngineer` and `FabricMigrationEngineer` ship only as `.agent.md` and `.toml`. Adding plain `.md` versions makes them loadable in Claude Code and must keep each dialect's body equivalent and keep the one-to-one `.toml` pairing.
- Do the install refresh through the sanctioned path, `setup-claude-plugins.ps1`, which registers or refreshes the repo marketplace and installs plugins, instead of hand-copying into the cache.

## Capabilities

### New Capabilities

- `devops/jira-work-trigger`: Routes "work on <KEY>" and related start phrases to `jira-workflow`, and requires `git-branch-guard` to pass before any ticket branch is created, switched, or changed.

### Modified Capabilities

- `repo-tooling/claude-code-packaging`: Agent Markdown files must parse in Claude Code (frontmatter at byte 0, no byte order mark), and the validation tooling must flag a violation.
- `devops/pr-creation`: Extends PR creation from Azure DevOps-only to host-aware creation: `gh pr create` for GitHub remotes and `az repos pr create` for Azure DevOps remotes.

Existing specs that already cover agent behavior and are not changed here: `powerbi/pql-tester-agent` (operating modes), `codex-plugin-compatibility` (one `.toml` adapter per top-level agent Markdown file). This change must stay consistent with both.

Plugin install refresh, the Fabric agent decision, and the `spec-lifecycle` decision are environment or decision tasks with no change to specified behavior, so they are tracked in tasks.md only.

## Impact

- `plugins/devops/skills/jira-workflow/SKILL.md`, `plugins/devops/agents/devops.agent.md`, and `plugins/devops/agents/devops.md` (trigger lists).
- `plugins/devops/skills/git-branch-guard/` (branch-guard handoff wording).
- `plugins/devops/skills/git-branch-guard/assets/create_pr.ps1`, `assets/create_pr.sh`, and the SKILL.md dependency section.
- `~/.claude` install state: enabled-plugin settings and the installed plugin cache. These need explicit approval before any change.
- No Jira API or MCP server configuration changes.
- `plugins/devops/agents/devops.toml`, `devops.agent.md`, `devops.md` (same trigger edit in all three dialects).
- `plugins/powerbi/agents/pql-tester.md` (remove the byte order mark) and `tools/validate-skills.ps1` (BOM check and a devops trigger-phrase parity check).
- `plugins/fabric/agents/` (Claude-format `.md` versions, if approved).
- `setup-claude-plugins.ps1` (used for the refresh; not edited).
- `.github/prompts/git-branch-guard.md`: stale `.txt` reference now points to the `.ps1` and `.sh` scripts.

## Findings (from SCRUM-24)

- `powerbi` installed at 0.3.0; repo is 0.5.0. Missing skills: dax-test-framework, dax-unit-testing, paginated-report-authoring.
- `fabric` installed at 0.2.0, same number as the repo but different content. Only fabric-cli is present; the other 12 skills and `common/` docs are missing. The FabricIQ HTTP MCP server is missing.
- `devops` installed at 0.1.0; repo is 0.2.0. Missing the troubleshooting-workflow skill and the `.ps1`/`.sh` scripts.
- `spec-lifecycle` (0.1.0) is in the repo but not installed.
- `pql-tester` agent is not in the session agent list, though its `.md` file is in the cache. Not yet confirmed as a load failure. Likely cause found in the repo: `plugins/powerbi/agents/pql-tester.md` starts with a UTF-8 byte order mark, and no other agent Markdown file does. Confirm by loading it in a fresh session after the fix.
- Fabric agents exist only as `.agent.md` and `.toml` (Copilot and Codex formats), so Claude Code cannot load them.
- Azure CLI (`az`) is needed only for Azure DevOps repos. It is not on this shell's PATH; check with `az --version`.
- `gh` is installed and logged in (account `iourichadour`) and covers GitHub repos.
- devops `git-branch-guard` PR creation works only for Azure DevOps: `create_pr.ps1` and `create_pr.sh` call `az repos pr create` only.
- The installed cache under `~/.claude/plugins/cache/powerbi-agentic-plugins` is stale. All four plugins (powerbi, fabric, devops, skill-creator) are enabled at user scope in `~/.claude/settings.json`, so they load in every project.

## GitHub PR Support Scope (from SCRUM-24)

- Detect the host from `git remote get-url origin`.
- `github.com` remote: create the PR with `gh pr create` (same title, body, base).
- `dev.azure.com` remote: keep the existing `az repos pr create` path.
- Update both `create_pr.ps1` and `create_pr.sh`.
- Update the SKILL.md dependency section to explain both paths.

## Test Plan (from SCRUM-24)

1. In a new Claude Code session, say "work on SCRUM-24" and check which skills trigger.
2. Confirm `jira-workflow` fetches the ticket, assigns it and moves it to In Progress without asking (decided by the user, replacing the ticket's "asks before any transition" wording), and asks before any comment or any write on another ticket.
3. Confirm `git-branch-guard` checks for a `feature/` or `bugfix/` branch that includes the Jira key.
4. On a GitHub repo, confirm PR creation uses `gh pr create`.
5. On an Azure DevOps repo, confirm PR creation still uses `az repos pr create`.

Jira: [SCRUM-24](https://iourichadour.atlassian.net/browse/SCRUM-24). Repo: `C:\Development\powerbi-agentic-plugins`.

## Approval Gates (from SCRUM-24)

Each of these needs explicit user approval before it runs. Repo edits inside this repository do not.

- Any change under `~/.claude` (settings, enabled plugins, installed cache).
- Replacing or removing installed plugin folders.
- Installing software such as `az`.
- Adding or changing MCP server configuration (including restoring the FabricIQ HTTP MCP server).
- Creating, editing, or transitioning other Jira issues, or posting comments.
- Pushing commits or opening PRs.

## Acceptance Criteria (from SCRUM-24)

- Installed plugin versions match the repo `marketplace.json` versions (powerbi 0.5.0, fabric 0.2.0, devops 0.2.0, skill-creator 1.0.0).
- Every skill in the repo plugin folders is present in the installed cache.
- spec-lifecycle is installed and enabled, or the decision not to install it is recorded.
- `pql-tester` loads as an agent, or the failure is documented.
- The decision on Claude-format agents for fabric is recorded (add `.md` versions or leave them out).
- `az` is documented as needed only for Azure DevOps repositories.
- PR creation works for both GitHub (`gh`) and Azure DevOps (`az`) repositories.
- Verified in a fresh Claude Code session outside the repo folder.
