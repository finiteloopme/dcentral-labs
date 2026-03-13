---
description: Create, list, or manage GitHub issues
agent: git-ops
---

$ARGUMENTS

The orchestrator is responsible for synthesizing conversation context into
$ARGUMENTS before invoking this command. If the conversation contains
relevant context (brainstorming results, discussion findings, decisions),
it MUST be inlined here. Do NOT ask the user to re-state context.

If no arguments are provided, list all open issues.

If arguments describe a bug, feature, or task, create a new issue with:
- An appropriate title derived from the description
- A well-structured markdown body with Summary, Scope, and Acceptance
  Criteria sections
- Suggested labels based on the content (bug, feature, chore, and priority)
- Association with a milestone if the user mentions one

After creating the issue, analyze the codebase to understand existing
patterns, conventions, and files that will need to be created or modified,
then post an implementation plan as a comment on the issue containing:
- Prerequisites and delivery details (files to create/modify, branch name)
- Step-by-step implementation instructions with specific content
- Verification checklist

If arguments reference an issue number (e.g., "#42" or just "42"), view
that issue.

If arguments say to update an issue with findings, context, or discussion
results, post a structured comment on the issue summarizing:
- Key decisions and rationale
- New findings or analysis results
- Updated scope or requirements (if changed)
- Next steps

If arguments say to close, reopen, or modify an issue, do that.
