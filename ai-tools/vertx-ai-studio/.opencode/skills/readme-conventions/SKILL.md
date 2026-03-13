---
name: readme-conventions
description: Conventions and best practices for writing minimalist README.md files
---

## What I do

- Guide the structure and content of README.md files
- Enforce minimalist documentation principles
- Provide templates and examples for different project types

## When to use me

Use this skill when writing or reviewing README.md files. It ensures
consistency and quality across projects.

## Principles

1. **One screen rule** -- A README should fit on one screen when possible.
   If it needs scrolling, you're writing too much.

2. **Copy-paste quickstart** -- A new developer should be able to copy-paste
   the quickstart commands and have the project running in under 2 minutes.

3. **No aspirational content** -- Document what exists, not what you plan
   to build. Use GitHub issues for the roadmap.

4. **Link, don't inline** -- If detailed docs exist elsewhere (wiki, /docs,
   external site), link to them. Don't duplicate content.

5. **Version-aware prerequisites** -- Always specify minimum versions for
   prerequisites when it matters.

## Structure Template

```markdown
# Project Name

One sentence describing what this project does.

## Prerequisites

- [Runtime](https://link) >= version
- [Tool](https://link)

## Quickstart

\```bash
git clone <repo-url>
cd <project>
<install-command>
<run-command>
\```

## License

MIT
```

## Anti-patterns to Avoid

- **Badge walls** -- Rows of status badges that nobody reads
- **Table of contents** -- If you need one, your README is too long
- **Screenshots of text** -- Use actual text and code blocks
- **Changelog in README** -- Use GitHub releases
- **TODO lists** -- Use GitHub issues
- **Exhaustive API docs** -- Belong in dedicated docs, not README
- **"Coming soon" sections** -- Either it exists or it doesn't
- **Duplicate info** -- Don't repeat what's in package.json or the code

## Per-language Conventions

### JavaScript/TypeScript
```markdown
## Prerequisites
- [Node.js](https://nodejs.org) >= 18
- [pnpm](https://pnpm.io) (or npm/yarn/bun)

## Quickstart
\```bash
pnpm install
pnpm dev
\```
```

### Go
```markdown
## Prerequisites
- [Go](https://go.dev) >= 1.21

## Quickstart
\```bash
go mod download
go run .
\```
```

### Python
```markdown
## Prerequisites
- [Python](https://python.org) >= 3.10

## Quickstart
\```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python main.py
\```
```

### Rust
```markdown
## Prerequisites
- [Rust](https://rustup.rs) (stable)

## Quickstart
\```bash
cargo build
cargo run
\```
```

## README Workflow

### Analysis Approach

When analyzing a project for README generation, examine:

1. Package manifests -- `package.json`, `go.mod`, `Cargo.toml`,
   `pyproject.toml`, `requirements.txt`, `pom.xml`, `build.gradle`
2. Entry points -- `main.*`, `index.*`, `app.*`, `src/`
3. Build/run scripts -- `Makefile`, `Dockerfile`, `docker-compose.yml`, `scripts/`
4. Existing documentation -- current README, CONTRIBUTING, `docs/`
5. Git history -- recent activity and project direction
6. CI configuration -- `.github/workflows/`, `.gitlab-ci.yml`

### Agent Integration

- Focus exclusively on README.md files for documentation.
- When generating README, follow the minimalist structure template above.
- When validating README, check against the actual project state. Identify
  stale instructions, missing prerequisites, or broken commands.
- Do not add TODO comments or task lists to README. Delegate TODOs to
  GitHub issues via `@git-ops`.
