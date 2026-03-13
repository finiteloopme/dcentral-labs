---
description: List and clean up pilot experiment workspaces
agent: pilot
---

$ARGUMENTS

This is a workspace cleanup workflow.

1. Use `pilot-workspace_list` to show all active workspaces with their age
   and disk usage.

2. If $ARGUMENTS contains "all" or "--all":
   - Confirm with the user, then use `pilot-workspace_destroy_all`.

3. If $ARGUMENTS contains a specific workspace name:
   - Use `pilot-workspace_destroy` to remove that specific workspace.

4. If $ARGUMENTS contains "--stale" or no arguments:
   - Identify workspaces older than 24 hours.
   - List them and ask the user which to clean up.
   - Destroy confirmed workspaces one by one.

5. Show a summary of what was cleaned up (count, total space freed).
