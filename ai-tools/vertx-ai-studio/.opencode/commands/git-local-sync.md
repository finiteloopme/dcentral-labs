---
description: Sync local default branch (main) with latest remote commits
agent: git-ops
subtask: true
---

Sync the local repository's default branch with the latest remote commits.

**This command is an authorized exception to the workspace isolation rule —
it operates directly on the main working tree to sync the default branch.**

1. Determine the default branch name (usually `main` or `master`)
2. Check current branch and working tree status:
   - Note the current branch name (to return to it later if needed)
   - If there are uncommitted changes (staged, unstaged, or untracked),
     ask the user: "You have uncommitted changes. Stash and continue,
     or abort?" Wait for explicit confirmation before proceeding.
   - If stashing, use `stash_push` with message "git-local-sync: auto-stash"
3. Fetch the latest from remote: `git fetch origin`
4. Switch to the default branch (if not already on it)
5. Fast-forward to the latest remote commits: `git merge --ff-only origin/<default-branch>`
   - If fast-forward fails (local has diverged), report the error and
     DO NOT force merge. Suggest the user resolve manually.
6. If the user was on a different branch before sync:
   - Switch back to the original branch
7. If changes were stashed in step 2:
   - Pop the stash with `stash_pop`
   - If stash pop has conflicts, report them clearly
8. Report a summary:
   - Previous HEAD vs new HEAD (commits pulled)
   - Current branch (restored to original if applicable)
   - Stash status (restored or N/A)
