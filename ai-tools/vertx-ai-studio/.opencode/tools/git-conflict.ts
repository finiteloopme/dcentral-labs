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

export const detect = tool({
  description:
    "Detect merge conflicts in the working tree and list all conflicted files. " +
    "Returns conflict status and the list of files with conflicts.",
  args: {
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    // Check for unmerged paths
    const result = await gitRun(["diff", "--name-only", "--diff-filter=U"], args.workspace)

    if (!result || result === "") {
      return "No merge conflicts detected."
    }

    if (result.startsWith("Error:")) return result

    const files = result.split("\n").filter(Boolean)
    const lines = [
      `Found ${files.length} file(s) with merge conflicts:`,
      "",
    ]
    for (const f of files) {
      lines.push(`  - ${f}`)
    }
    return lines.join("\n")
  },
})

export const show = tool({
  description:
    "Show the conflict markers in a specific file. " +
    "Displays the full file content with <<<<<<< / ======= / >>>>>>> markers highlighted.",
  args: {
    path: tool.schema
      .string()
      .describe("Path to the file with conflicts"),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    const envErr = await ensureEnvironment()
    if (envErr) return envErr

    try {
      const filePath = args.workspace
        ? `${args.workspace}/${args.path}`
        : args.path
      const content = await Bun.$`cat ${filePath}`.text()
      if (!content.includes("<<<<<<<")) {
        return `No conflict markers found in ${args.path}.`
      }
      return `Conflict markers in ${args.path}:\n\n${content}`
    } catch (e: any) {
      return `Error reading ${args.path}: ${e.message || "file not found"}`
    }
  },
})

export const abort_merge = tool({
  description:
    "Abort an in-progress merge and return to the pre-merge state.",
  args: {
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    return await gitRun(["merge", "--abort"], args.workspace)
  },
})
