---
description: Test a hypothesis in an isolated throwaway workspace
agent: pilot
---

$ARGUMENTS

The user wants to test a hypothesis or answer a question through experimentation.

1. **Interpret the hypothesis** — Parse $ARGUMENTS to understand what the user
   wants to test. If the hypothesis is unclear, ask for clarification.

2. **Plan the experiment** — Briefly state:
   - What you'll test
   - What language/runtime you'll use
   - What a CONFIRMED vs REFUTED result looks like

3. **Create a workspace** — Use `pilot-workspace_create` with an appropriate
   name derived from the hypothesis and the correct project type.

4. **Write test code** — Use bash to write minimal test files into the workspace.
   Keep experiments as small as possible — the goal is to answer the question,
   not build a project.

5. **Run the experiment** — Use `pilot-run_execute` to run the test code.

6. **Report the result** — Present a structured verdict:
   - **CONFIRMED** — The hypothesis is true, with evidence
   - **REFUTED** — The hypothesis is false, with evidence
   - **INCONCLUSIVE** — Could not determine, explain why

7. **Offer next steps**:
   - Run a follow-up experiment
   - Create a GitHub issue for significant findings (delegate to @git-ops)
   - Clean up the workspace
   - Keep the workspace for further exploration

If no arguments are provided, ask the user what they want to test.
