---
description: Review a pull request, fix issues, and merge
agent: devops
---

Review PR #$ARGUMENTS

NOTE: If $ARGUMENTS is empty or does not contain a PR number, delegate to
@git-ops to list open PRs and ask which one to review.

**This is a review workflow — skip the pre-flight protocol.** No issue
number is required. The PR itself provides all necessary context.

## Phase 1: Review (delegate to @git-ops)

1. Delegate to @git-ops to get the PR details and full diff
2. Delegate to @git-ops to analyze the changes for:
   - Code quality and best practices
   - Potential bugs or edge cases
   - Performance implications
   - Security concerns (no hardcoded secrets, input validation)
   - Missing tests or documentation
3. @git-ops provides structured feedback with specific file/line references
4. @git-ops gives an overall assessment: approve, request changes, or comment

## Phase 2: Act on review outcome

### If approved (no issues found):
5. Delegate to @git-ops to approve the PR
6. Delegate to @git-ops to squash merge the PR with delete_branch: true
7. Report: PR merged, summary of review

### If changes requested:
5. Delegate to @git-ops to submit the review with requested changes
6. Ask the user: "Issues were found. Want me to fix them? [yes/no]"
   - **If no**: Leave the review comments for the PR author. Report and stop.
   - **If yes**: Proceed to Phase 3.

## Phase 3: Fix and re-review (max 2 iterations)

7. Check out the PR branch in an isolated workspace
   (use agent_workspace_create)
8. Fix the issues identified in the review
9. Stage, commit, and push the fixes (delegate to @git-ops with workspace path)
10. Re-review: delegate to @git-ops to get the updated PR diff and re-analyze
11. If clean → delegate to @git-ops to approve and squash merge with
    delete_branch: true
12. If issues remain after 2 remediation rounds → leave the PR open with
    a review comment listing remaining issues for manual review
13. Destroy workspace (agent_workspace_destroy)
14. Report: PR status (merged or open with remaining issues), summary of
    fixes applied
