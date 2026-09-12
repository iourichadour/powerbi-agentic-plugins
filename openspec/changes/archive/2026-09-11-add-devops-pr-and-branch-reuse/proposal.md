## Why

Jira FIN-1813 reports two gaps in the `git-branch-guard` workflow discovered while setting up the Azure DevOps CLI: (1) starting work on a ticket blindly creates a new branch even when a matching `feature/`/`bugfix/` branch already exists locally or on the remote, risking duplicate/divergent branches, and (2) there is no supported way to open an Azure DevOps pull request from the agent — PR creation is currently a fully manual, undocumented step even though the `az devops`/`az repos` CLI is already installed and configured for the `bayviewasset` org.

## What Changes

- Add a branch-existence check to the start-of-work flow: before creating a `feature/<KEY>-...` or `bugfix/<KEY>-...` branch, check for an existing local or remote branch containing the same Jira key. If found, tell the user it already exists and ask whether to switch to it instead of creating a new one.
- Add a PR-creation capability using the Azure DevOps CLI (`az repos pr create`), triggered only in two ways:
  - Explicit user request (e.g., "create a PR", "open a PR for this").
  - Offered (not auto-created) immediately after a `git commit` when the current branch is a Jira ticket branch (`feature/`/`bugfix/` with a ticket key).
  - In both cases, the exact PR plan (source branch, target branch, title, repo) must be shown and explicitly confirmed by the user before the PR is created — no auto-creation.
- Default the PR's target/base branch to `DEV` whenever the source is a Jira ticket branch, while still letting the user override the target branch when asked or when they specify one.
- Document the Azure DevOps CLI as a dependency of `git-branch-guard` (extension, login, and `organization`/`project` defaults) since PR creation depends on it being installed and authenticated.

## Capabilities

### New Capabilities
- `devops/git-branch-reuse`: Detect an existing local/remote branch matching the current Jira ticket key before creating a new one, and prompt the user to switch instead of duplicating it.
- `devops/pr-creation`: Create an Azure DevOps pull request via the `az repos pr create` CLI, triggered explicitly or offered post-commit, always gated on explicit user confirmation of the shown plan, defaulting the target branch to `DEV` for ticket branches.

### Modified Capabilities
<!-- none: no existing openspec/specs/devops capabilities exist yet -->

## Impact

- `plugins/devops/skills/git-branch-guard/SKILL.md` and `check_git_branch_guard.ps1` (or a new companion script) — add branch-existence lookup and switch-prompt behavior, and document the Azure DevOps CLI dependency.
- `plugins/devops/skills/git-branch-guard/` — new PR-creation script/asset invoking `az repos pr create`.
- `plugins/devops/skills/git-branch-guard/assets/azure-devops-cli-setup.md` (relocated from a non-distributed top-level `plans/` folder) and new `assets/setup_azure_cli.ps1` — automate the one-time Azure CLI + extension setup this change's PR-creation capability depends on.
- `plugins/devops/agents/devops.agent.md` — orchestration steps for the new post-commit PR offer and the branch-reuse check.
- No changes to Jira-side tooling (`jira-workflow` skill is unaffected; it still only supplies `ticket_key` + `short_description`).
