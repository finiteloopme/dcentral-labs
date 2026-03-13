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

const PROTECTED_BRANCHES = ["main", "master", "develop", "production"]

export const create = tool({
  description:
    "Create a new git branch. Optionally specify a base branch and whether to check it out immediately.",
  args: {
    name: tool.schema.string().describe("Name for the new branch"),
    base: tool.schema
      .string()
      .optional()
      .describe("Base branch to create from (default: current branch)"),
    checkout: tool.schema
      .boolean()
      .optional()
      .describe("Switch to the new branch after creating it (default: true)"),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    const shouldCheckout = args.checkout !== false

    if (shouldCheckout) {
      const flags = ["checkout", "-b", args.name]
      if (args.base) flags.push(args.base)
      return await gitRun(flags, args.workspace)
    } else {
      const flags = ["branch", args.name]
      if (args.base) flags.push(args.base)
      return await gitRun(flags, args.workspace)
    }
  },
})

export const switch_branch = tool({
  description: "Switch to an existing branch.",
  args: {
    name: tool.schema.string().describe("Branch name to switch to"),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    return await gitRun(["checkout", args.name], args.workspace)
  },
})

export const delete_branch = tool({
  description:
    "Delete a branch. Refuses to delete protected branches (main, master, develop, production) " +
    "unless force is true. Uses -d by default (safe delete), -D with force.",
  args: {
    name: tool.schema.string().describe("Branch name to delete"),
    force: tool.schema
      .boolean()
      .optional()
      .describe("Force delete even if unmerged or protected (default: false)"),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    if (PROTECTED_BRANCHES.includes(args.name) && !args.force) {
      return (
        `Error: Refusing to delete protected branch '${args.name}'. ` +
        `Pass force=true to override this safety check.`
      )
    }

    const flag = args.force ? "-D" : "-d"
    return await gitRun(["branch", flag, args.name], args.workspace)
  },
})

export const list = tool({
  description:
    "List branches. Shows local branches by default, or include remote branches.",
  args: {
    remote: tool.schema
      .boolean()
      .optional()
      .describe("Include remote branches (default: false)"),
    pattern: tool.schema
      .string()
      .optional()
      .describe("Glob pattern to filter branches (e.g., 'feature/*')"),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    const flags: string[] = ["branch"]
    if (args.remote) flags.push("-a")
    flags.push("-v")
    if (args.pattern) flags.push("--list", args.pattern)

    return await gitRun(flags, args.workspace)
  },
})

export const rename = tool({
  description: "Rename a branch.",
  args: {
    old_name: tool.schema.string().describe("Current branch name"),
    new_name: tool.schema.string().describe("New branch name"),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    if (PROTECTED_BRANCHES.includes(args.old_name)) {
      return `Error: Refusing to rename protected branch '${args.old_name}'.`
    }
    return await gitRun(["branch", "-m", args.old_name, args.new_name], args.workspace)
  },
})

export const current = tool({
  description: "Show the current branch name.",
  args: {
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    return await gitRun(["rev-parse", "--abbrev-ref", "HEAD"], args.workspace)
  },
})
