import { tool } from "@opencode-ai/plugin"
import { ensureEnvironment } from "./git-ops-init"

const WORKSPACE_DESC =
  "Path to an agent workspace (clone). When provided, git commands run " +
  "inside the workspace instead of the main working tree. Use the path " +
  "returned by agent_workspace_create."

async function gitRun(args: string[], workspace?: string): Promise<string> {
  const envErr = await ensureEnvironment()
  if (envErr) return envErr

  try {
    const cmd = workspace
      ? Bun.$`git -C ${workspace} ${args}`
      : Bun.$`git ${args}`
    const result = await cmd.text()
    return result.trim()
  } catch (e: any) {
    const stderr = e?.stderr?.toString?.()?.trim() || ""
    return `Error: ${stderr || e.message || "unknown error"}`
  }
}

export const status = tool({
  description:
    "Show the current working tree status including staged, unstaged, and untracked files.",
  args: {
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    return await gitRun(["status"], args.workspace)
  },
})

export const log = tool({
  description:
    "Show commit log. Returns recent commits with hash, author, date, and message.",
  args: {
    limit: tool.schema
      .number()
      .optional()
      .describe("Max number of commits to show (default: 10)"),
    oneline: tool.schema
      .boolean()
      .optional()
      .describe("Use one-line format (default: false)"),
    author: tool.schema
      .string()
      .optional()
      .describe("Filter by author name or email"),
    since: tool.schema
      .string()
      .optional()
      .describe("Show commits since date (e.g., '2024-01-01', '1 week ago')"),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    const flags: string[] = [`-n${args.limit || 10}`]
    if (args.oneline) flags.push("--oneline")
    if (args.author) flags.push(`--author=${args.author}`)
    if (args.since) flags.push(`--since=${args.since}`)

    return await gitRun(["log", ...flags], args.workspace)
  },
})

export const diff = tool({
  description:
    "Show changes between commits, working tree, or staged area.",
  args: {
    path: tool.schema
      .string()
      .optional()
      .describe("Specific file or directory to diff"),
    staged: tool.schema
      .boolean()
      .optional()
      .describe("Show staged (cached) changes instead of unstaged"),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    const flags: string[] = []
    if (args.staged) flags.push("--cached")
    if (args.path) flags.push("--", args.path)

    return await gitRun(["diff", ...flags], args.workspace)
  },
})

export const blame = tool({
  description:
    "Show who last modified each line of a file with commit info.",
  args: {
    path: tool.schema.string().describe("File path to blame"),
    lines: tool.schema
      .string()
      .optional()
      .describe("Line range to blame (e.g., '10,20' for lines 10-20)"),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    const flags: string[] = []
    if (args.lines) {
      const [start, end] = args.lines.split(",")
      flags.push(`-L${start},${end}`)
    }
    flags.push(args.path)

    return await gitRun(["blame", ...flags], args.workspace)
  },
})

export const stash_list = tool({
  description: "List all stashed changes.",
  args: {
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    const result = await gitRun(["stash", "list"], args.workspace)
    return result || "No stashes found."
  },
})

export const stash_push = tool({
  description:
    "Stash current uncommitted changes with an optional message.",
  args: {
    message: tool.schema
      .string()
      .optional()
      .describe("Message to describe the stash"),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    const flags: string[] = ["stash", "push"]
    if (args.message) flags.push("-m", args.message)

    return await gitRun(flags, args.workspace)
  },
})

export const stash_pop = tool({
  description: "Apply the most recent stash and remove it from the stash list.",
  args: {
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    return await gitRun(["stash", "pop"], args.workspace)
  },
})
