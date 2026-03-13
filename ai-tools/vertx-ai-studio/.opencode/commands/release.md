---
description: Create a new release with auto-generated notes
agent: git-ops
---

$ARGUMENTS

1. List recent releases to determine the current version
2. Analyze commits since the last release to determine the appropriate
   version bump (major, minor, patch) based on conventional commits:
   - feat: -> minor bump
   - fix: -> patch bump
   - BREAKING CHANGE or !: -> major bump
3. Generate release notes from commits
4. Show the proposed version and notes to the user for review
5. If the user provided a specific version in arguments, use that instead
6. Create the release after user confirmation
