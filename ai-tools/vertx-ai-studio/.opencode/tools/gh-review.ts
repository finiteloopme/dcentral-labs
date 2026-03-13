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
    return `Error: ${stderr || e.message || "unknown error"}`
  }
}

export const diff = tool({
  description:
    "Get the full diff for a pull request. Useful for code review.",
  args: {
    number: tool.schema.number().describe("PR number to get diff for"),
  },
  async execute(args) {
    if (args.number <= 0) return "Error: PR number must be a positive integer."
    return await ghRun(["pr", "diff", String(args.number)])
  },
})

export const approve = tool({
  description: "Approve a pull request with an optional review comment.",
  args: {
    number: tool.schema.number().describe("PR number to approve"),
    body: tool.schema
      .string()
      .optional()
      .describe("Optional review comment"),
  },
  async execute(args) {
    if (args.number <= 0) return "Error: PR number must be a positive integer."

    const flags: string[] = [
      "pr",
      "review",
      String(args.number),
      "--approve",
    ]
    if (args.body) flags.push("--body", args.body)

    return await ghRun(flags)
  },
})

export const request_changes = tool({
  description:
    "Request changes on a pull request. Requires a review comment explaining what needs to change.",
  args: {
    number: tool.schema.number().describe("PR number to request changes on"),
    body: tool.schema
      .string()
      .describe("Review comment explaining the requested changes"),
  },
  async execute(args) {
    if (args.number <= 0) return "Error: PR number must be a positive integer."

    return await ghRun([
      "pr",
      "review",
      String(args.number),
      "--request-changes",
      "--body",
      args.body,
    ])
  },
})

export const comment_on_pr = tool({
  description: "Leave a general review comment on a pull request.",
  args: {
    number: tool.schema.number().describe("PR number to comment on"),
    body: tool.schema.string().describe("Review comment in markdown"),
  },
  async execute(args) {
    if (args.number <= 0) return "Error: PR number must be a positive integer."

    return await ghRun([
      "pr",
      "review",
      String(args.number),
      "--comment",
      "--body",
      args.body,
    ])
  },
})

export const list_reviews = tool({
  description:
    "List existing reviews on a pull request.",
  args: {
    number: tool.schema.number().describe("PR number"),
  },
  async execute(args) {
    if (args.number <= 0) return "Error: PR number must be a positive integer."

    const raw = await ghRun([
      "api",
      `repos/{owner}/{repo}/pulls/${args.number}/reviews`,
      "--jq",
      '.[] | "\\(.user.login) [\\(.state)] \\(.submitted_at // "pending"): \\(.body // "(no comment)")"',
    ])
    if (raw.startsWith("Error:") || raw.includes("FATAL:")) return raw

    return raw || "No reviews found."
  },
})
