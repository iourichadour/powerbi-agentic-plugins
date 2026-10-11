## MODIFIED Requirements

### Requirement: PR creation is only triggered explicitly or offered post-commit
The system SHALL initiate PR creation only when the user explicitly requests it (e.g., "create a PR", "open a PR for this"), or by offering it immediately after a `git commit` the agent performs on a `feature/`/`bugfix/` branch that contains a Jira ticket key. It SHALL NOT create a PR automatically in any other case.

#### Scenario: Explicit user request
- **WHEN** the user asks to create or open a pull request
- **THEN** the system prepares a PR creation plan and does not create anything without confirmation

#### Scenario: Offered after a commit on a ticket branch
- **WHEN** the agent performs a `git commit` while the current branch is a `feature/`/`bugfix/` branch containing a Jira ticket key
- **THEN** the system asks the user whether to open a PR for this branch

#### Scenario: No automatic offer for non-ticket branches
- **WHEN** the agent performs a `git commit` on a branch that is not a Jira ticket branch
- **THEN** the system does not offer or create a PR automatically

### Requirement: PR plan must be shown and confirmed before creation
The system SHALL display the exact PR plan — repository, source branch, target branch, and title — and SHALL require explicit user confirmation before creating the pull request.

#### Scenario: Plan displayed before creation
- **WHEN** PR creation is triggered by either an explicit request or a post-commit offer that the user accepts
- **THEN** the system shows the repository, source branch, target branch, and title, and asks the user to confirm before proceeding

#### Scenario: User confirms
- **WHEN** the user confirms the displayed PR plan
- **THEN** the system creates the pull request using the exact values shown

#### Scenario: User declines
- **WHEN** the user declines the displayed PR plan
- **THEN** the system does not create the pull request and takes no further action

### Requirement: Default PR target branch for Jira ticket branches
The system SHALL default the PR's target (base) branch to `DEV` whenever the source branch is a Jira ticket branch, unless the user specifies a different target branch.

#### Scenario: Default target applied
- **WHEN** the user does not specify a target branch and the source branch is a Jira ticket branch
- **THEN** the PR plan defaults the target branch to `DEV`

#### Scenario: User overrides the target branch
- **WHEN** the user specifies a target branch different from `DEV`
- **THEN** the PR plan uses the user-specified target branch instead of the default

### Requirement: PR creation requires a working Azure DevOps CLI
Before creating a pull request, the system SHALL verify the CLI required by the detected host is available and usable. For GitHub, this is `gh` with an authenticated session. For Azure DevOps, this is the `az` CLI with the `azure-devops` extension, an authenticated session, and configured organization/project defaults or explicit equivalents. The Azure DevOps CLI SHALL be required only for Azure DevOps remotes.

#### Scenario: GitHub CLI prerequisite missing
- **WHEN** the origin is a GitHub remote and `gh` is not installed or not authenticated
- **THEN** the system reports the specific missing prerequisite to the user instead of attempting the PR creation or failing silently

#### Scenario: CLI prerequisite missing
- **WHEN** the origin is an Azure DevOps remote and the `azure-devops` extension is missing, the CLI session is not authenticated, or no organization/project is resolvable
- **THEN** the system reports the specific missing prerequisite to the user instead of attempting the PR creation or failing silently

#### Scenario: GitHub repo does not need Azure CLI
- **WHEN** the origin is a GitHub remote and `az` is not installed
- **THEN** the system does not report `az` as a missing prerequisite

## ADDED Requirements

### Requirement: PR host is detected from the origin remote
The system SHALL detect the repository host from `git remote get-url origin` before creating a pull request. A `github.com` remote SHALL use the GitHub CLI (`gh pr create`). A `dev.azure.com` remote SHALL use the Azure DevOps CLI (`az repos pr create`). Any other host SHALL be reported to the user as unsupported, and no pull request SHALL be created.

#### Scenario: GitHub remote
- **WHEN** the origin remote host is `github.com`
- **THEN** the system creates the PR with `gh pr create` using the title, body, and target branch shown in the confirmed plan

#### Scenario: Azure DevOps remote
- **WHEN** the origin remote host is `dev.azure.com`
- **THEN** the system creates the PR with `az repos pr create` using the values shown in the confirmed plan

#### Scenario: Unsupported remote
- **WHEN** the origin remote host is neither `github.com` nor `dev.azure.com`
- **THEN** the system reports the host as unsupported and does not attempt to create a pull request
