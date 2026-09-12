## Purpose

Ensures the `powerbi-developer` agent verifies each task it implements against that task's own acceptance criteria before marking it complete, closing a gap where tasks could be checked off without validation.

## ADDED Requirements

### Requirement: Task completion requires acceptance-criteria validation
When implementing a spec's task plan, the `powerbi-developer` agent SHALL validate the output of each task against that task's stated acceptance criteria (or, absent explicit per-task criteria, the relevant requirement/scenario in the spec) before marking the task done. The agent SHALL NOT mark a task done if that validation fails or cannot be performed; it SHALL instead report the specific gap to the user and leave the task unchecked.

#### Scenario: Task passes its acceptance criteria
- **WHEN** the agent completes a task whose implementation satisfies the task's acceptance criteria (or the corresponding spec requirement/scenario)
- **THEN** the agent SHALL mark the task done in the plan/spec

#### Scenario: Task fails its acceptance criteria
- **WHEN** the agent completes work for a task but the result does not satisfy that task's acceptance criteria (or the corresponding spec requirement/scenario)
- **THEN** the agent SHALL NOT mark the task done, and SHALL report which criterion failed and why

#### Scenario: Acceptance criteria cannot be evaluated
- **WHEN** the agent cannot determine whether a task's output meets its acceptance criteria (e.g., criteria are missing, ambiguous, or require information the agent cannot obtain)
- **THEN** the agent SHALL leave the task unchecked and SHALL ask the user or state what additional information is needed, rather than marking it done
