import { tool } from "@opencode-ai/plugin"

const WORKSPACE_DESC =
  "Path to an agent workspace (clone). When provided, git commands run " +
  "inside the workspace instead of the main working tree. Use the path " +
  "returned by agent_workspace_create."

async function run(
  cmd: string[],
  workspace?: string,
): Promise<{ ok: boolean; out: string }> {
  try {
    const proc = workspace
      ? Bun.$`${cmd}`.cwd(workspace)
      : Bun.$`${cmd}`
    const result = await proc.text()
    return { ok: true, out: result.trim() }
  } catch (e: any) {
    return {
      ok: false,
      out: e?.stderr?.toString?.()?.trim() || e.message || "unknown error",
    }
  }
}

const PROTECTED_BRANCHES = ["main", "master", "develop", "production"]

export const list_stale = tool({
  description:
    "List branches that have been merged into the default branch. " +
    "Shows branch name, last commit date, and merge status for both " +
    "local and remote branches.",
  args: {
    include_remote: tool.schema
      .boolean()
      .optional()
      .describe("Also check remote branches (default: true)"),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    const includeRemote = args.include_remote !== false
    const ws = args.workspace

    // Get default branch
    const defaultResult = await run([
      "gh",
      "repo",
      "view",
      "--json",
      "defaultBranchRef",
      "--jq",
      ".defaultBranchRef.name",
    ], ws)
    const defaultBranch = defaultResult.ok ? defaultResult.out : "main"

    // Get current branch
    const currentResult = await run(["git", "rev-parse", "--abbrev-ref", "HEAD"], ws)
    const currentBranch = currentResult.ok ? currentResult.out : ""

    const lines: string[] = ["Stale Branch Report", "===================", ""]

    // Local merged branches
    const localMerged = await run(["git", "branch", "--merged", defaultBranch], ws)
    if (localMerged.ok && localMerged.out) {
      const branches = localMerged.out
        .split("\n")
        .map((b) => b.trim().replace(/^\* /, ""))
        .filter((b) => b && !PROTECTED_BRANCHES.includes(b) && b !== currentBranch)

      if (branches.length > 0) {
        lines.push(`Local merged branches (${branches.length}):`)
        for (const branch of branches) {
          // Get last commit date
          const dateResult = await run([
            "git",
            "log",
            "-1",
            "--format=%cr",
            branch,
          ], ws)
          const date = dateResult.ok ? dateResult.out : "unknown"
          lines.push(`  ${branch}  (${date})`)
        }
      } else {
        lines.push("Local merged branches: none")
      }
    } else {
      lines.push("Local merged branches: none")
    }

    lines.push("")

    // Remote merged branches
    if (includeRemote) {
      // Fetch latest remote info
      await run(["git", "fetch", "--prune"], ws)

      const remoteMerged = await run([
        "git",
        "branch",
        "-r",
        "--merged",
        defaultBranch,
      ], ws)

      if (remoteMerged.ok && remoteMerged.out) {
        const branches = remoteMerged.out
          .split("\n")
          .map((b) => b.trim())
          .filter(
            (b) =>
              b &&
              !b.includes("HEAD") &&
              !PROTECTED_BRANCHES.some((p) => b.endsWith(`/${p}`)),
          )

        if (branches.length > 0) {
          lines.push(`Remote merged branches (${branches.length}):`)
          for (const branch of branches) {
            const dateResult = await run([
              "git",
              "log",
              "-1",
              "--format=%cr",
              branch,
            ], ws)
            const date = dateResult.ok ? dateResult.out : "unknown"
            lines.push(`  ${branch}  (${date})`)
          }
        } else {
          lines.push("Remote merged branches: none")
        }
      } else {
        lines.push("Remote merged branches: none")
      }
    }

    lines.push("")
    lines.push("Use the 'prune' tool to delete merged branches.")

    return lines.join("\n")
  },
})

export const prune = tool({
  description:
    "Delete branches that have been merged into the default branch. " +
    "Requires confirmation. Skips protected branches (main, master, develop, production).",
  args: {
    confirm: tool.schema
      .boolean()
      .describe(
        "Set to true to confirm deletion. MUST be true or the operation is rejected.",
      ),
    include_remote: tool.schema
      .boolean()
      .optional()
      .describe("Also delete remote merged branches (default: false)"),
    workspace: tool.schema
      .string()
      .optional()
      .describe(WORKSPACE_DESC),
  },
  async execute(args) {
    if (!args.confirm) {
      return (
        "REFUSED: You must set confirm=true to delete branches. " +
        "Run 'list_stale' first to review which branches will be removed."
      )
    }

    const ws = args.workspace

    // Get default branch
    const defaultResult = await run([
      "gh",
      "repo",
      "view",
      "--json",
      "defaultBranchRef",
      "--jq",
      ".defaultBranchRef.name",
    ], ws)
    const defaultBranch = defaultResult.ok ? defaultResult.out : "main"

    // Get current branch
    const currentResult = await run(["git", "rev-parse", "--abbrev-ref", "HEAD"], ws)
    const currentBranch = currentResult.ok ? currentResult.out : ""

    const results: string[] = ["Branch Cleanup Results", "=====================", ""]

    // Delete local merged branches
    const localMerged = await run(["git", "branch", "--merged", defaultBranch], ws)
    if (localMerged.ok && localMerged.out) {
      const branches = localMerged.out
        .split("\n")
        .map((b) => b.trim().replace(/^\* /, ""))
        .filter((b) => b && !PROTECTED_BRANCHES.includes(b) && b !== currentBranch)

      if (branches.length > 0) {
        results.push("Local branches:")
        for (const branch of branches) {
          const del = await run(["git", "branch", "-d", branch], ws)
          if (del.ok) {
            results.push(`  Deleted: ${branch}`)
          } else {
            results.push(`  Failed:  ${branch} (${del.out})`)
          }
        }
      } else {
        results.push("Local branches: nothing to clean")
      }
    }

    results.push("")

    // Delete remote merged branches
    if (args.include_remote) {
      await run(["git", "fetch", "--prune"], ws)

      const remoteMerged = await run([
        "git",
        "branch",
        "-r",
        "--merged",
        defaultBranch,
      ], ws)

      if (remoteMerged.ok && remoteMerged.out) {
        const branches = remoteMerged.out
          .split("\n")
          .map((b) => b.trim())
          .filter(
            (b) =>
              b &&
              !b.includes("HEAD") &&
              !PROTECTED_BRANCHES.some((p) => b.endsWith(`/${p}`)),
          )

        if (branches.length > 0) {
          results.push("Remote branches:")
          for (const remoteBranch of branches) {
            // Extract remote and branch name (e.g., "origin/feature/42-foo" -> remote="origin", branch="feature/42-foo")
            const slashIdx = remoteBranch.indexOf("/")
            if (slashIdx === -1) continue
            const remote = remoteBranch.slice(0, slashIdx)
            const branchName = remoteBranch.slice(slashIdx + 1)

            const del = await run(["git", "push", remote, "--delete", branchName], ws)
            if (del.ok) {
              results.push(`  Deleted: ${remoteBranch}`)
            } else {
              results.push(`  Failed:  ${remoteBranch} (${del.out})`)
            }
          }
        } else {
          results.push("Remote branches: nothing to clean")
        }
      }
    }

    results.push("")

    // Final prune of stale tracking refs
    await run(["git", "fetch", "--prune"], ws)
    results.push("Stale remote-tracking references pruned.")

    return results.join("\n")
  },
})
