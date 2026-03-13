---
description: Stage changes and create a conventional commit
agent: git-ops
---

$ARGUMENTS

1. Check the current git status
2. If nothing is staged, show the unstaged changes and ask what to stage
3. Show the staged diff for review
4. Generate a conventional commit message based on the changes:
   - Use format: type(scope): description
   - Types: feat, fix, chore, docs, refactor, test, style, perf, ci, build
   - Keep the description concise but descriptive
5. If the user provided a message in the arguments, use that instead
6. Create the commit
