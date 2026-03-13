import { tool } from "@opencode-ai/plugin"
import { ensureEnvironment } from "./git-ops-init"

async function ghRun(args: string[]): Promise<string> {
  const envErr = await ensureEnvironment()
  if (envErr) return envErr

  try {
    const result = await Bun.$`gh ${args}`.text()
    return result.trim()
  } catch (e: any) {
    const stderr = e?.stderr?.toString?.()?.trim() || ""
    const msg = e?.message || "unknown error"
    return `Error: ${stderr || msg}`
  }
}

function buildFlags(opts: Record<string, string | boolean | undefined>): string[] {
  const flags: string[] = []
  for (const [key, val] of Object.entries(opts)) {
    if (val === undefined || val === false || val === "") continue
    const flag = `--${key}`
    if (val === true) {
      flags.push(flag)
    } else {
      flags.push(flag, val)
    }
  }
  return flags
}

export const create = tool({
  description:
    "Create a new GitHub issue. Use for feature requests, bug reports, or tasks. " +
    "Returns the issue number and URL.",
  args: {
    title: tool.schema.string().describe("Issue title"),
    body: tool.schema.string().describe("Issue body/description in markdown"),
    labels: tool.schema
      .string()
      .optional()
      .describe("Comma-separated labels (e.g., 'bug,priority:high')"),
    milestone: tool.schema
      .string()
      .optional()
      .describe("Milestone name to associate with (e.g., 'v1.0')"),
    assignees: tool.schema
      .string()
      .optional()
      .describe("Comma-separated GitHub usernames to assign"),
    project: tool.schema
      .string()
      .optional()
      .describe("GitHub Project name to add the issue to"),
  },
  async execute(args) {
    const flags = buildFlags({
      title: args.title,
      body: args.body,
      label: args.labels,
      milestone: args.milestone,
      assignee: args.assignees,
      project: args.project,
    })
    return await ghRun(["issue", "create", ...flags])
  },
})

export const list = tool({
  description:
    "List GitHub issues with optional filters. " +
    "Returns a formatted list of issues with number, title, state, labels, and assignees.",
  args: {
    state: tool.schema
      .enum(["open", "closed", "all"])
      .optional()
      .describe("Filter by state (default: open)"),
    labels: tool.schema
      .string()
      .optional()
      .describe("Comma-separated labels to filter by"),
    milestone: tool.schema
      .string()
      .optional()
      .describe("Milestone name to filter by"),
    assignee: tool.schema
      .string()
      .optional()
      .describe("GitHub username to filter by assignee"),
    limit: tool.schema
      .number()
      .optional()
      .describe("Max number of issues to return (default: 30)"),
    search: tool.schema
      .string()
      .optional()
      .describe("Search query to filter issues"),
  },
  async execute(args) {
    const flags = buildFlags({
      state: args.state || "open",
      label: args.labels,
      milestone: args.milestone,
      assignee: args.assignee,
      limit: String(args.limit || 30),
      search: args.search,
    })
    flags.push(
      "--json",
      "number,title,state,labels,assignees,milestone,createdAt,updatedAt,author",
    )

    const raw = await ghRun(["issue", "list", ...flags])
    if (raw.startsWith("Error:") || raw.includes("FATAL:")) return raw

    try {
      const issues = JSON.parse(raw)
      if (issues.length === 0) return "No issues found matching the filters."

      const lines: string[] = [`Found ${issues.length} issue(s):`, ""]
      for (const issue of issues) {
        const labels =
          issue.labels?.map((l: any) => l.name).join(", ") || "none"
        const assignees =
          issue.assignees?.map((a: any) => a.login).join(", ") || "unassigned"
        const milestone = issue.milestone?.title || "none"
        lines.push(`#${issue.number} [${issue.state}] ${issue.title}`)
        lines.push(`   Labels: ${labels}  |  Assignees: ${assignees}  |  Milestone: ${milestone}`)
        lines.push(`   Author: ${issue.author?.login || "unknown"}  |  Created: ${issue.createdAt?.split("T")[0] || "unknown"}`)
        lines.push("")
      }
      return lines.join("\n")
    } catch {
      return raw
    }
  },
})

export const view = tool({
  description:
    "View a single GitHub issue with all details including body, labels, " +
    "milestone, assignees, and comments.",
  args: {
    number: tool.schema.number().describe("Issue number"),
  },
  async execute(args) {
    if (args.number <= 0) return "Error: Issue number must be a positive integer."

    const raw = await ghRun([
      "issue",
      "view",
      String(args.number),
      "--json",
      "number,title,state,body,labels,assignees,milestone,comments,createdAt,updatedAt,author,url",
    ])
    if (raw.startsWith("Error:") || raw.includes("FATAL:")) return raw

    try {
      const issue = JSON.parse(raw)
      const labels =
        issue.labels?.map((l: any) => l.name).join(", ") || "none"
      const assignees =
        issue.assignees?.map((a: any) => a.login).join(", ") || "unassigned"
      const milestone = issue.milestone?.title || "none"

      const lines: string[] = [
        `Issue #${issue.number}: ${issue.title}`,
        `State: ${issue.state}  |  Author: ${issue.author?.login || "unknown"}`,
        `Labels: ${labels}`,
        `Assignees: ${assignees}`,
        `Milestone: ${milestone}`,
        `Created: ${issue.createdAt?.split("T")[0] || "unknown"}  |  Updated: ${issue.updatedAt?.split("T")[0] || "unknown"}`,
        `URL: ${issue.url}`,
        "",
        "--- Body ---",
        issue.body || "(no description)",
      ]

      if (issue.comments && issue.comments.length > 0) {
        lines.push("")
        lines.push(`--- Comments (${issue.comments.length}) ---`)
        for (const comment of issue.comments) {
          lines.push("")
          lines.push(
            `${comment.author?.login || "unknown"} (${comment.createdAt?.split("T")[0] || "unknown"}):`
          )
          lines.push(comment.body)
        }
      }

      return lines.join("\n")
    } catch {
      return raw
    }
  },
})

export const update = tool({
  description:
    "Update an existing GitHub issue. Change title, body, labels, milestone, or assignees. " +
    "Only the fields you provide will be updated.",
  args: {
    number: tool.schema.number().describe("Issue number to update"),
    title: tool.schema.string().optional().describe("New title"),
    body: tool.schema.string().optional().describe("New body/description"),
    add_labels: tool.schema
      .string()
      .optional()
      .describe("Comma-separated labels to add"),
    remove_labels: tool.schema
      .string()
      .optional()
      .describe("Comma-separated labels to remove"),
    milestone: tool.schema
      .string()
      .optional()
      .describe("Milestone name to set"),
    assignees: tool.schema
      .string()
      .optional()
      .describe("Comma-separated GitHub usernames to assign (replaces existing)"),
  },
  async execute(args) {
    if (args.number <= 0) return "Error: Issue number must be a positive integer."

    const flags: string[] = []
    if (args.title) flags.push("--title", args.title)
    if (args.body) flags.push("--body", args.body)
    if (args.add_labels) flags.push("--add-label", args.add_labels)
    if (args.remove_labels) flags.push("--remove-label", args.remove_labels)
    if (args.milestone) flags.push("--milestone", args.milestone)
    if (args.assignees) {
      // --add-assignee replaces behavior for issue edit
      for (const a of args.assignees.split(",")) {
        flags.push("--add-assignee", a.trim())
      }
    }

    if (flags.length === 0) {
      return "Error: No fields to update. Provide at least one of: title, body, add_labels, remove_labels, milestone, assignees."
    }

    return await ghRun(["issue", "edit", String(args.number), ...flags])
  },
})

export const close = tool({
  description:
    "Close a GitHub issue. Optionally provide a reason (completed or not_planned).",
  args: {
    number: tool.schema.number().describe("Issue number to close"),
    reason: tool.schema
      .enum(["completed", "not planned"])
      .optional()
      .describe("Reason for closing (default: completed)"),
    comment: tool.schema
      .string()
      .optional()
      .describe("Optional comment to add before closing"),
  },
  async execute(args) {
    if (args.number <= 0) return "Error: Issue number must be a positive integer."

    // Add comment first if provided
    if (args.comment) {
      await ghRun(["issue", "comment", String(args.number), "--body", args.comment])
    }

    const flags: string[] = []
    if (args.reason) flags.push("--reason", args.reason)

    return await ghRun(["issue", "close", String(args.number), ...flags])
  },
})

export const reopen = tool({
  description: "Reopen a previously closed GitHub issue.",
  args: {
    number: tool.schema.number().describe("Issue number to reopen"),
    comment: tool.schema
      .string()
      .optional()
      .describe("Optional comment to add when reopening"),
  },
  async execute(args) {
    if (args.number <= 0) return "Error: Issue number must be a positive integer."

    if (args.comment) {
      await ghRun(["issue", "comment", String(args.number), "--body", args.comment])
    }

    return await ghRun(["issue", "reopen", String(args.number)])
  },
})

export const comment = tool({
  description: "Add a comment to a GitHub issue.",
  args: {
    number: tool.schema.number().describe("Issue number to comment on"),
    body: tool.schema.string().describe("Comment body in markdown"),
  },
  async execute(args) {
    if (args.number <= 0) return "Error: Issue number must be a positive integer."
    return await ghRun(["issue", "comment", String(args.number), "--body", args.body])
  },
})
