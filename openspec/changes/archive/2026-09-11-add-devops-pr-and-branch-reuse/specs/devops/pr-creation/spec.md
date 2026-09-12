## Purpose

Adds a confirmed, Azure DevOps CLI-backed pull request creation capability that is only triggered by an explicit user request or offered after a commit on a ticket branch, never created automatically.

## ADDED Requirements

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
The system SHALL verify that the Azure DevOps CLI is available (the `az` CLI with the `azure-devops` extension installed, an authenticated session, and configured organization/project defaults or explicit equivalents) before attempting to create a pull request.

#### Scenario: CLI prerequisite missing
- **WHEN** the `azure-devops` extension is missing, the CLI session is not authenticated, or no organization/project is resolvable
- **THEN** the system reports the specific missing prerequisite to the user instead of attempting the PR creation or failing silently
