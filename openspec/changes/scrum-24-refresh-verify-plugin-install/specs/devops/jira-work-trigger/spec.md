## Purpose

Makes a plain request to work on a Jira ticket, such as "work on SCRUM-24", reliably start the Jira workflow, so the ticket is fetched, assigned, and transitioned before the Git branch guard checks or creates the working branch.

## ADDED Requirements

### Requirement: Work-on phrasing triggers the start-ticket workflow
The system SHALL treat "work on <KEY>" (case-insensitive, with an optional leading "I want to", "let's", or "I'm going to") as a start-ticket trigger, in addition to the existing phrases "start <KEY>", "pick up <KEY>", and "I'm starting <KEY>", where `<KEY>` matches `[A-Z]+-\d+`. Matching SHALL route to the `jira-workflow` skill before any branch is created or code is changed.

#### Scenario: Bare work-on phrase
- **WHEN** the user says "work on SCRUM-24"
- **THEN** the system runs the `jira-workflow` start-ticket steps for `SCRUM-24`

#### Scenario: Existing phrasings still work
- **WHEN** the user says "I want to work on FIN-1740" or "start FIN-1740"
- **THEN** the system runs the same start-ticket steps as for "work on <KEY>"

#### Scenario: No ticket key in the message
- **WHEN** the user says "work on this ticket" without a key matching `[A-Z]+-\d+`
- **THEN** the system asks the user which ticket key to use and does not guess one

### Requirement: Branch guard runs before any ticket branch is created or switched
After `jira-workflow` has fetched the ticket, the system SHALL hand the ticket key and a derived short description to `git-branch-guard` and SHALL NOT create, rename, or switch to a ticket branch until the guard passes. Branch creation SHALL NOT run directly from the trigger handler.

#### Scenario: Guard passes after a valid branch is created
- **WHEN** the start-ticket steps complete and no compliant branch exists for the key
- **THEN** `git-branch-guard` creates a `feature/<KEY>-<short-description>` or `bugfix/<KEY>-<short-description>` branch and validates it before any code change starts

#### Scenario: Guard fails on a non-compliant branch
- **WHEN** the current branch is protected (for example `dev` or `main`), lacks a `bugfix/` or `feature/` prefix, or lacks an uppercase Jira key
- **THEN** the system reports the failing rule, suggests a compliant branch name, and does not start implementation until the guard passes

#### Scenario: Existing compliant branch
- **WHEN** a compliant branch containing `<KEY>` already exists
- **THEN** the system runs the guard against it and reports that it is valid, without creating a new branch

### Requirement: Start-ticket flow assigns and starts the named ticket without asking
When the start-ticket flow runs for `<KEY>`, the system SHALL assign the ticket to the current user and transition it to In Progress without asking for confirmation. Any other Jira write SHALL require explicit user confirmation: edits or transitions on a different ticket, and every comment on any ticket.

#### Scenario: Named ticket is started automatically
- **WHEN** the user says "work on SCRUM-24" and the ticket is unassigned and To Do
- **THEN** the system assigns it to the user and moves it to In Progress, then continues to the branch guard, without a confirmation prompt

#### Scenario: Other ticket is not changed
- **WHEN** the user asks about another ticket while work on `<KEY>` is in progress
- **THEN** the system does not assign, transition, or comment on that other ticket without confirmation

#### Scenario: Comment needs confirmation
- **WHEN** the system would post a comment on any ticket, including the named one
- **THEN** it asks first and posts only after an explicit yes

### Requirement: Trigger phrases are identical across agent dialects
The start-ticket trigger phrases SHALL be identical in the devops persona agent's Claude Code file (`devops.md`), Copilot file (`devops.agent.md`), and Codex adapter (`devops.toml`), and in the `jira-workflow` skill, and a change to one SHALL be made in all of them in the same edit.

#### Scenario: New trigger phrase added
- **WHEN** "work on <KEY>" is added to the start-ticket trigger list
- **THEN** all three agent dialect files and `jira-workflow` SKILL.md list the same phrase

#### Scenario: Dialects drift apart
- **WHEN** one dialect lists a start-ticket phrase that another omits
- **THEN** `tools/validate-skills.ps1` fails and names the file and the missing phrase, including when "work on <KEY>" is the missing phrase
