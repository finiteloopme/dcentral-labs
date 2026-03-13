---
description: Scaffold Makefile, scripts, container files, Cloud Build, and Terraform for the project
agent: devops
---

$ARGUMENTS

This is a project scaffolding workflow.

1. Detect the project type (Node, Go, Python, etc.).
2. Ask the user what to scaffold:
   - **Everything** (Makefile + scripts + container files + Cloud Build + Terraform + .gitignore)
   - **Local dev only** (Makefile + scripts + .gitignore)
   - **Container dev** (Makefile + scripts + container files + .gitignore)
   - **Full CI/CD** (all of the above + Cloud Build + Terraform)
3. If CI/CD is selected, confirm the user wants Terraform executed via Cloud
   Build (plan on PR, apply on merge).
4. Run the `scaffold` tool with the appropriate `components` parameter
   (or omit `components` for everything).
5. Show a summary of all files created/skipped.
6. Follow the standard post-work protocol.
