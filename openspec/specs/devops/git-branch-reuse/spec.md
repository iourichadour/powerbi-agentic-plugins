## Purpose

Prevents duplicate or divergent Git branches for the same Jira ticket by checking whether a matching `feature/`/`bugfix/` branch already exists (locally or on the remote) before a new one is created, and offering to switch to it instead.

## Requirements

### Requirement: Detect existing branch before creating a new one
Before creating a `feature/<KEY>-<description>` or `bugfix/<KEY>-<description>` branch for a Jira ticket key, the system SHALL check both local branches and remote-tracking branches for an existing branch name containing that ticket key.

#### Scenario: No matching branch exists
- **WHEN** the user starts work on ticket `<KEY>` and no local or remote branch name contains `<KEY>`
- **THEN** the system creates the new `feature/<KEY>-<description>` (or `bugfix/`) branch as usual

#### Scenario: Matching branch exists locally
- **WHEN** a local branch containing `<KEY>` already exists
- **THEN** the system informs the user the branch already exists and asks whether to switch to it instead of creating a new branch

#### Scenario: Matching branch exists only on the remote
- **WHEN** no local branch contains `<KEY>` but a remote-tracking branch does
- **THEN** the system informs the user of the existing remote branch and asks whether to fetch/check it out locally and switch to it instead of creating a new branch

### Requirement: User controls whether to switch
The system SHALL NOT switch branches or create a new branch automatically once an existing match is found — it SHALL wait for the user's explicit choice.

#### Scenario: User agrees to switch
- **WHEN** the system reports an existing branch for `<KEY>` and the user agrees to switch
- **THEN** the system checks out the existing branch (fetching it first if it is remote-only) and does not create a new branch

#### Scenario: User declines switching
- **WHEN** the system reports an existing branch for `<KEY>` and the user declines to switch
- **THEN** the system does not create a duplicate branch automatically and asks the user how to proceed (for example, a different branch name or description) instead of silently creating one anyway
