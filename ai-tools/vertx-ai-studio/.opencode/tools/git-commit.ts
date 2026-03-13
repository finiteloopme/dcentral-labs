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

export const stage = tool({
  description:
    "Stage files for commit. Use '.' to stage all changes, or provide specific paths.",
  args: {
    paths: tool.schema
      .string()
      .describe("Space-separated file paths to stage, or '.' for all"),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    const paths = args.paths.split(/\s+/).filter(Boolean)
    if (paths.length === 0) return "Error: No paths provided."

    return await gitRun(["add", ...paths], args.workspace)
  },
})

export const commit = tool({
  description:
    "Create a commit with the staged changes. Provide a commit message. " +
    "If no changes are staged, returns an error.",
  args: {
    message: tool.schema
      .string()
      .describe(
        "Commit message. Prefer conventional commit format: type(scope): description"
      ),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    // Check if there are staged changes
    const staged = await gitRun(["diff", "--cached", "--stat"], args.workspace)
    if (!staged || staged === "" || staged.startsWith("Error:")) {
      return "Error: No staged changes to commit. Stage files first with the stage tool."
    }

    return await gitRun(["commit", "-m", args.message], args.workspace)
  },
})

export const amend = tool({
  description:
    "Amend the last commit. Optionally change the message. " +
    "WARNING: Do not amend commits that have been pushed to a shared remote.",
  args: {
    message: tool.schema
      .string()
      .optional()
      .describe("New commit message (if omitted, keeps the existing message)"),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    // Check if HEAD has been pushed
    const pushed = await gitRun([
      "log",
      "--oneline",
      "HEAD",
      "--not",
      "--remotes",
      "-n1",
    ], args.workspace)
    if (pushed === "" || pushed.startsWith("Error:")) {
      return (
        "WARNING: The last commit appears to have been pushed to a remote. " +
        "Amending will require a force push. Aborting for safety. " +
        "If you really want to amend, use git bash directly."
      )
    }

    const flags = ["commit", "--amend"]
    if (args.message) {
      flags.push("-m", args.message)
    } else {
      flags.push("--no-edit")
    }

    return await gitRun(flags, args.workspace)
  },
})

export const unstage = tool({
  description: "Unstage files (remove from staging area without losing changes).",
  args: {
    paths: tool.schema
      .string()
      .describe("Space-separated file paths to unstage, or '.' for all"),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    const paths = args.paths.split(/\s+/).filter(Boolean)
    if (paths.length === 0) return "Error: No paths provided."

    return await gitRun(["restore", "--staged", ...paths], args.workspace)
  },
})

export const diff_staged = tool({
  description: "Show the diff of currently staged changes (what will be committed).",
  args: {
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    const result = await gitRun(["diff", "--cached"], args.workspace)
    return result || "No staged changes."
  },
})
