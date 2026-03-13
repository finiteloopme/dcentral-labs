---
name: git-pr-workflow
description: Best practices for creating and reviewing pull requests
---

## What I do

- Guide PR creation with proper title, description, and metadata
- Provide a review checklist for code reviews
- Suggest merge strategy based on project conventions

## When to use me

Use this skill when creating or reviewing pull requests. It helps ensure
consistent PR quality and thorough reviews.

## PR Title Conventions

Use a descriptive title that summarizes the change:
- `feat: add user authentication flow`
- `fix: resolve login timeout on mobile`
- `chore: update dependency versions`
- `docs: add API documentation for /users endpoint`

Keep titles under 72 characters.

## PR Description Template

Structure PR descriptions as:

```markdown
## Summary
Brief description of what this PR does and why.

## Changes
- List of specific changes made
- Each change on its own line

## Testing
- How were these changes tested?
- Any manual testing steps?

## Related Issues
Closes #123
Relates to #456
```

## Review Checklist

When reviewing a PR, check for:

### Code Quality
- [ ] Code follows project conventions and style
- [ ] No unnecessary complexity or duplication
- [ ] Functions and variables have clear, descriptive names
- [ ] Error handling is appropriate

### Correctness
- [ ] Logic is correct and handles edge cases
- [ ] No off-by-one errors or boundary issues
- [ ] Null/undefined checks where needed

### Security
- [ ] No hardcoded secrets or credentials
- [ ] Input validation on user-facing interfaces
- [ ] No SQL injection or XSS vulnerabilities

### Performance
- [ ] No unnecessary database queries or API calls
- [ ] No N+1 query patterns
- [ ] Large data sets are paginated

### Testing
- [ ] Tests cover the main functionality
- [ ] Edge cases have test coverage
- [ ] Tests are readable and maintainable

### Documentation
- [ ] Public APIs are documented
- [ ] Complex logic has comments explaining "why"
- [ ] README updated if needed

## Merge Strategy

- **Squash merge**: Use when the PR has many small commits that should be
  combined into one clean commit. Best for feature branches.
- **Merge commit**: Use when you want to preserve the full commit history.
  Best for release branches.
- **Rebase**: Use when you want a linear history without merge commits.
  Best for small, focused changes.

## Linking Issues

Use GitHub keywords to automatically close issues when the PR is merged:
- `Closes #123` - Closes issue #123 when merged
- `Fixes #123` - Same as Closes
- `Resolves #123` - Same as Closes
- `Relates to #123` - Links without closing
