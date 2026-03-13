---
description: Implement an issue from its plan, commit, create PR, review, and merge
agent: devops
---

Implement issue #$ARGUMENTS

NOTE: If $ARGUMENTS is empty, contains a non-numeric value, or references
conversation context (e.g., "the issue we discussed"), STOP and report
back that the orchestrator must provide a specific issue number. Do NOT
ask the user to re-state context that already exists in the conversation.

1. Run full pre-flight checks for the issue
2. Read the issue and find the implementation plan (look for a comment
   containing "## Implementation Plan")
3. If no plan exists, stop and tell the user to add a plan first
4. Execute each step in the plan sequentially
5. After all steps are complete, follow the post-work protocol:
   - Validate documentation (delegate to @docs for readme-validate)
   - Run test validation
   - Stage and commit with conventional commit message referencing the issue
   - Create a PR that closes the issue
6. Self-review the PR:
   - Delegate to @git-ops to get the PR diff and review against the
     code quality checklist (correctness, security, performance, docs)
   - If issues are found, fix them in the workspace, commit, push,
     and re-review (max 2 iterations)
   - If issues persist after 2 rounds, leave the PR open with a comment
     listing remaining issues for manual review
7. If the review is clean, squash merge the PR and delete the branch
8. Report the PR URL, review outcome, and merge status
