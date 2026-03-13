---
description: Run DevOps tasks with pre-flight checks (issue link, clean tree, dedicated branch)
agent: devops
---

$ARGUMENTS

If $ARGUMENTS is empty, report back that the orchestrator must provide a
specific task description. Do NOT ask the user to re-state context.

## Context Handling

$ARGUMENTS may contain a structured brief from the orchestrator with labeled
sections: Task, Issue, Context, Implementation Plan, Files to Create/Modify,
and Acceptance Criteria. When a structured brief is provided:

1. **Issue number present** — Extract the issue number from the `## Issue`
   section and use it for pre-flight checks.
2. **No issue number** — If the brief describes work that should be tracked
   but no issue number is included, create an issue first (delegate to
   `@git-ops` with the Task and Context sections as the issue body), then
   run pre-flight with the newly created issue number.
3. **Implementation Plan** — Use the `## Implementation Plan` section, if
   present, as the execution guide. This plan was produced by the Plan agent
   and contains specific file paths, changes, and steps.
4. **Acceptance Criteria** — Use the `## Acceptance Criteria` section, if
   present, to verify the work after completion.

Execute the requested DevOps task. The agent's pre-flight and post-work
protocols apply automatically.
