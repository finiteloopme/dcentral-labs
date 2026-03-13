---
name: devops-workflow
description: Issue-driven DevOps workflow with pre-flight checks, workspace isolation, and PR lifecycle
---

## What I do

- Define the mandatory pre-flight protocol for all DevOps work
- Guide branch naming conventions for issue-linked branches
- Document workspace isolation for branch safety
- Document the full lifecycle from issue to merged PR
- Provide post-merge cleanup procedures

## When to use me

Use this skill when starting any DevOps task, when unsure about the workflow
order, or when onboarding someone to the issue-driven development process.

## Pre-flight Protocol

Every task follows this sequence before work begins:

```
1. Issue Check     ->  Verify GitHub issue exists and is open
2. Clean Tree      ->  No uncommitted changes in main working directory
3. Workspace Setup ->  Clone repo to isolated /tmp/agent-<name>/ directory
4. Branch Create   ->  Dedicated branch created in the workspace
5. Plan Check      ->  Implementation plan posted on the issue
```

**CRITICAL**: After pre-flight, verify you are NOT on the default branch.
The agent must never commit directly to main/master. If somehow on the
default branch, STOP and re-run preflight.

All checks must PASS before any work begins. If any check fails, stop and
resolve the issue before proceeding.

### Workspace Isolation

The pre-flight protocol creates a fully isolated git clone in `/tmp/agent-*`.
This ensures:

- The main working tree's branch NEVER changes
- Multiple subagents can work on different branches concurrently
- No shared state (stash, hooks, config) between sessions
- Clean teardown: `rm -rf /tmp/agent-*`

After preflight passes, ALL operations must target the workspace path:
- Pass `workspace` parameter to all git tools
- Use workspace path as `workdir` for bash commands
- Write/edit files inside the workspace directory

## Branch Naming Convention

Format: `<type>/<issue-number>-<slug>`

| Type | When to use |
|------|-------------|
| `feature` | New functionality |
| `fix` | Bug fixes |
| `chore` | Maintenance, dependency updates, config changes |
| `docs` | Documentation changes |
| `refactor` | Code restructuring without behavior change |
| `test` | Adding or updating tests |

Examples:
- `feature/42-add-dark-mode`
- `fix/17-login-timeout`
- `chore/5-update-terraform-provider`
- `docs/23-update-deployment-guide`

Rules:
- Slug is derived from the issue title, kebab-cased, max 40 characters
- Always branch from the default branch (usually `main`)
- One branch per issue, one issue per branch

## Full Lifecycle

```
Issue Created
  │
  v
Pre-flight Checks (issue, clean tree, workspace + branch, plan)
  │
  v
Work Execution (in isolated workspace — containers, infra, troubleshooting)
  │
  v
Test Validation (mandatory — PASS / FAIL / WARN — run in workspace)
  │
  v
Stage & Commit (via @git-ops with workspace path, conventional commit format)
  │
  v
Create PR (via @git-ops with workspace path, with "Closes #N" in body)
  │         - Always set delete_branch: true
  v
Self-Review PR (via @git-ops — diff analysis against review checklist)
  │
  ├── Clean ──────────────────────────┐
  │                                   v
  ├── Issues Found ──> Fix ──> Re-review (max 2 iterations)
  │                               │
  │                     ├── Clean ─┤
  │                     │          v
  │                     └── Still issues ──> Leave PR open with comment
  │                                          │
  v                                          v
Merge PR (squash, delete branch)      Destroy Workspace & Report
  │
  v
Destroy Workspace & Report
```

## Test Validation

Test validation is a **mandatory** step between work execution and commit.
It runs automatically via the `validate_tests` tool (with the workspace path)
and MUST NOT be silently skipped.

### Detection Priority

The tool searches for test infrastructure in this order:

1. `make local-test` — Makefile target (preferred, uses `scripts/local.sh test`)
2. `make test` — Fallback Makefile target
3. **Auto-detect** — Infers test command from project type (e.g., `npm test`,
   `go test ./...`, `python3 -m pytest`, `cargo test`)

### Outcomes

| Result | Meaning | Action |
|--------|---------|--------|
| **PASS** | Tests ran and passed | Proceed to commit |
| **FAIL** | Tests ran and failed | Show output. User must explicitly confirm to skip. |
| **WARN** | No test infrastructure found | User must explicitly confirm to proceed. Suggest tracking issue. |

### Skip Override Rules

- The user **CAN** skip test validation, but **MUST** explicitly confirm.
- The agent **MUST NOT** silently skip or auto-confirm on behalf of the user.
- If tests fail, the prompt must include: "Tests failed. Do you want to skip
  test validation and commit anyway? This is not recommended."
- If no tests exist, the prompt must include: "No test infrastructure was
  found. Do you want to proceed without test validation?"
- Skipping should be the exception, not the norm.

## Self-Review Protocol

After creating the PR, the agent MUST self-review before merging. This is
delegated to `@git-ops` and is never skipped.

### Process

1. Delegate to `@git-ops` to get the full PR diff
2. `@git-ops` analyzes the diff against the review checklist
3. If issues are found:
   - Fix them in the workspace (which must still be alive)
   - Stage, commit, and push fixes via `@git-ops`
   - Re-request a review from `@git-ops` on the updated PR
   - Maximum **2 remediation iterations**
4. If clean (or after successful remediation): merge via `@git-ops`
   using squash merge with `delete_branch: true`
5. If issues persist after 2 rounds: leave PR open with a review
   comment listing remaining issues for manual review

### Review Checklist

The self-review checks for:

- Code follows project conventions and style
- No hardcoded secrets or credentials
- Error handling is appropriate
- No unnecessary complexity or duplication
- Logic is correct and handles edge cases
- Public APIs are documented
- README updated if needed

### Remediation Rules

- The workspace MUST remain alive until the review loop completes
- Each fix iteration requires a new commit (do not amend)
- After 2 failed iterations, the agent MUST stop and leave the PR open
- The agent MUST NOT skip the review or auto-approve without analysis

## Commit Message Convention

Use conventional commits: `type(scope): description`

- `feat(container): add multi-stage build for API service`
- `fix(terraform): correct GKE node pool machine type`
- `chore(gcloud): update project IAM bindings`
- `docs(readme): add deployment prerequisites`

## Post-merge Cleanup

After a PR is merged (either via the self-review-merge loop or manually),
clean up to prevent branch accumulation:

1. Destroy workspace: `agent_workspace_destroy` (if not already destroyed).
   The workspace is kept alive during the review loop for remediation fixes,
   and destroyed only after the PR is merged or the loop completes.
2. Delete local branch: `git branch -d <branch>` (in the main repo)
3. Prune remote refs: `git fetch --prune`

Use the `/cleanup` command to list and prune stale merged branches.
