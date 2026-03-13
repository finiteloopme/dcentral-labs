import { tool } from "@opencode-ai/plugin"
import { ensureEnvironment } from "./git-ops-init"

const WORKSPACE_DESC =
  "Path to an agent workspace (clone). When provided, gh commands run " +
  "inside the workspace instead of the main working tree. Use the path " +
  "returned by agent_workspace_create."

async function ghRun(args: string[], workspace?: string): Promise<string> {
  const envErr = await ensureEnvironment()
  if (envErr) return envErr

  try {
    const cmd = workspace
      ? Bun.$`gh ${args}`.cwd(workspace)
      : Bun.$`gh ${args}`
    const result = await cmd.text()
    return result.trim()
  } catch (e: any) {
    const stderr = e?.stderr?.toString?.()?.trim() || ""
    return `Error: ${stderr || e.message || "unknown error"}`
  }
}

export const create = tool({
  description:
    "Create a pull request from the current branch. Auto-pushes the branch if needed.",
  args: {
    title: tool.schema.string().describe("PR title"),
    body: tool.schema.string().describe("PR body/description in markdown"),
    base: tool.schema
      .string()
      .optional()
      .describe("Base branch to merge into (default: repo default branch)"),
    draft: tool.schema
      .boolean()
      .optional()
      .describe("Create as draft PR (default: false)"),
    labels: tool.schema
      .string()
      .optional()
      .describe("Comma-separated labels"),
    milestone: tool.schema
      .string()
      .optional()
      .describe("Milestone name"),
    assignees: tool.schema
      .string()
      .optional()
      .describe("Comma-separated GitHub usernames to assign"),
    reviewers: tool.schema
      .string()
      .optional()
      .describe("Comma-separated GitHub usernames to request review from"),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    const flags: string[] = ["pr", "create", "--title", args.title, "--body", args.body]

    if (args.base) flags.push("--base", args.base)
    if (args.draft) flags.push("--draft")
    if (args.labels) flags.push("--label", args.labels)
    if (args.milestone) flags.push("--milestone", args.milestone)
    if (args.assignees) flags.push("--assignee", args.assignees)
    if (args.reviewers) flags.push("--reviewer", args.reviewers)

    return await ghRun(flags, args.workspace)
  },
})

export const list = tool({
  description: "List pull requests with optional filters.",
  args: {
    state: tool.schema
      .enum(["open", "closed", "merged", "all"])
      .optional()
      .describe("Filter by state (default: open)"),
    labels: tool.schema
      .string()
      .optional()
      .describe("Comma-separated labels to filter by"),
    base: tool.schema
      .string()
      .optional()
      .describe("Filter by base branch"),
    author: tool.schema
      .string()
      .optional()
      .describe("Filter by author username"),
    limit: tool.schema
      .number()
      .optional()
      .describe("Max number of PRs to return (default: 30)"),
    search: tool.schema
      .string()
      .optional()
      .describe("Search query to filter PRs"),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    const flags: string[] = [
      "pr",
      "list",
      "--state",
      args.state || "open",
      "--limit",
      String(args.limit || 30),
      "--json",
      "number,title,state,author,labels,assignees,reviewRequests,headRefName,baseRefName,createdAt,url",
    ]

    if (args.labels) flags.push("--label", args.labels)
    if (args.base) flags.push("--base", args.base)
    if (args.author) flags.push("--author", args.author)
    if (args.search) flags.push("--search", args.search)

    const raw = await ghRun(flags, args.workspace)
    if (raw.startsWith("Error:") || raw.includes("FATAL:")) return raw

    try {
      const prs = JSON.parse(raw)
      if (prs.length === 0) return "No pull requests found matching the filters."

      const lines: string[] = [`Found ${prs.length} PR(s):`, ""]
      for (const pr of prs) {
        const labels = pr.labels?.map((l: any) => l.name).join(", ") || "none"
        const reviewers =
          pr.reviewRequests?.map((r: any) => r.login).join(", ") || "none"
        lines.push(
          `#${pr.number} [${pr.state}] ${pr.title}`
        )
        lines.push(
          `   ${pr.headRefName} -> ${pr.baseRefName}  |  Author: ${pr.author?.login || "unknown"}`
        )
        lines.push(
          `   Labels: ${labels}  |  Reviewers: ${reviewers}`
        )
        lines.push(`   URL: ${pr.url}`)
        lines.push("")
      }
      return lines.join("\n")
    } catch {
      return raw
    }
  },
})

export const view = tool({
  description: "View a single pull request with full details including diff stats.",
  args: {
    number: tool.schema.number().describe("PR number"),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    if (args.number <= 0) return "Error: PR number must be a positive integer."

    const raw = await ghRun([
      "pr",
      "view",
      String(args.number),
      "--json",
      "number,title,state,body,labels,assignees,reviewRequests,headRefName,baseRefName,additions,deletions,changedFiles,commits,comments,createdAt,mergedAt,url,author",
    ], args.workspace)
    if (raw.startsWith("Error:") || raw.includes("FATAL:")) return raw

    try {
      const pr = JSON.parse(raw)
      const labels = pr.labels?.map((l: any) => l.name).join(", ") || "none"
      const assignees =
        pr.assignees?.map((a: any) => a.login).join(", ") || "unassigned"
      const reviewers =
        pr.reviewRequests?.map((r: any) => r.login).join(", ") || "none"

      const lines: string[] = [
        `PR #${pr.number}: ${pr.title}`,
        `State: ${pr.state}  |  Author: ${pr.author?.login || "unknown"}`,
        `Branch: ${pr.headRefName} -> ${pr.baseRefName}`,
        `Labels: ${labels}`,
        `Assignees: ${assignees}  |  Reviewers: ${reviewers}`,
        `Files changed: ${pr.changedFiles}  |  +${pr.additions} -${pr.deletions}`,
        `Commits: ${pr.commits?.totalCount ?? pr.commits?.length ?? "unknown"}`,
        `Created: ${pr.createdAt?.split("T")[0] || "unknown"}${pr.mergedAt ? `  |  Merged: ${pr.mergedAt.split("T")[0]}` : ""}`,
        `URL: ${pr.url}`,
        "",
        "--- Body ---",
        pr.body || "(no description)",
      ]

      if (pr.comments && pr.comments.length > 0) {
        lines.push("")
        lines.push(`--- Comments (${pr.comments.length}) ---`)
        for (const c of pr.comments) {
          lines.push("")
          lines.push(`${c.author?.login || "unknown"} (${c.createdAt?.split("T")[0] || "unknown"}):`)
          lines.push(c.body)
        }
      }

      return lines.join("\n")
    } catch {
      return raw
    }
  },
})

export const merge = tool({
  description:
    "Merge a pull request. Choose merge method (merge, squash, rebase). " +
    "Optionally delete the head branch after merging.",
  args: {
    number: tool.schema.number().describe("PR number to merge"),
    method: tool.schema
      .enum(["merge", "squash", "rebase"])
      .optional()
      .describe("Merge method (default: merge)"),
    delete_branch: tool.schema
      .boolean()
      .optional()
      .describe("Delete the head branch after merging (default: false)"),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    if (args.number <= 0) return "Error: PR number must be a positive integer."

    const flags: string[] = ["pr", "merge", String(args.number)]
    const method = args.method || "merge"
    flags.push(`--${method}`)
    if (args.delete_branch) flags.push("--delete-branch")

    return await ghRun(flags, args.workspace)
  },
})

export const close = tool({
  description: "Close a pull request without merging.",
  args: {
    number: tool.schema.number().describe("PR number to close"),
    comment: tool.schema
      .string()
      .optional()
      .describe("Optional comment to add before closing"),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    if (args.number <= 0) return "Error: PR number must be a positive integer."

    if (args.comment) {
      await ghRun(["pr", "comment", String(args.number), "--body", args.comment], args.workspace)
    }

    return await ghRun(["pr", "close", String(args.number)], args.workspace)
  },
})

export const checkout = tool({
  description: "Check out a pull request branch locally.",
  args: {
    number: tool.schema.number().describe("PR number to check out"),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    if (args.number <= 0) return "Error: PR number must be a positive integer."
    return await ghRun(["pr", "checkout", String(args.number)], args.workspace)
  },
})
