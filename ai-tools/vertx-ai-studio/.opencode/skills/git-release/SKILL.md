---
name: git-release
description: Create consistent releases and changelogs using semantic versioning and conventional commits
---

## What I do

- Determine the next version based on conventional commit history
- Draft release notes from merged PRs and commits
- Provide a copy-pasteable `gh release create` command
- Follow semantic versioning (semver) conventions

## When to use me

Use this skill when preparing a tagged release. It helps ensure consistent
versioning and comprehensive changelogs.

## Versioning Rules

Follow semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR** version bump when:
  - A commit message contains `BREAKING CHANGE:` in the body
  - A commit type has `!` suffix (e.g., `feat!: remove API`)

- **MINOR** version bump when:
  - Commits include `feat:` or `feature:` types

- **PATCH** version bump when:
  - Commits include `fix:`, `perf:`, or `docs:` types
  - No feat or breaking changes present

## Release Notes Format

Structure release notes as:

```markdown
## What's Changed

### Breaking Changes
- Description of breaking change (#PR)

### New Features
- feat: description (#PR)

### Bug Fixes
- fix: description (#PR)

### Other Changes
- chore/refactor/docs: description (#PR)

**Full Changelog**: https://github.com/owner/repo/compare/v0.1.0...v0.2.0
```

## Workflow

1. Run `gh release list --limit 1` to find the latest release tag
2. Run `git log <last-tag>..HEAD --oneline` to see commits since last release
3. Categorize commits by type (feat, fix, chore, etc.)
4. Determine version bump based on commit types
5. Generate release notes in the format above
6. Present to user for review
7. Create the release with `gh release create`

## Pre-release Conventions

- Use `-alpha.N`, `-beta.N`, or `-rc.N` suffixes for pre-releases
- Mark pre-releases with the `--prerelease` flag
- Example: `v1.0.0-beta.1`, `v2.0.0-rc.1`
