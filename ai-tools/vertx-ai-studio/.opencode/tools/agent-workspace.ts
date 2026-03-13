import { tool } from "@opencode-ai/plugin"
import { existsSync, readFileSync, writeFileSync } from "fs"
import { join } from "path"
import { homedir } from "os"
import { randomBytes } from "crypto"

// ─── Types ───────────────────────────────────────────────────────────

interface Workspace {
  name: string
  path: string
  branch: string
  remoteUrl: string
  sourceProject: string
  createdAt: string
}

interface Manifest {
  workspaces: Workspace[]
}

// ─── Helpers ─────────────────────────────────────────────────────────

function getManifestPath(): string {
  return join(homedir(), ".agent-workspaces.json")
}

function readManifest(): Manifest {
  const path = getManifestPath()
  if (!existsSync(path)) {
    return { workspaces: [] }
  }
  try {
    return JSON.parse(readFileSync(path, "utf-8"))
  } catch {
    return { workspaces: [] }
  }
}

function writeManifest(manifest: Manifest): void {
  writeFileSync(getManifestPath(), JSON.stringify(manifest, null, 2) + "\n")
}

function generateHash(): string {
  return randomBytes(4).toString("hex")
}

async function run(cmd: string[]): Promise<{ ok: boolean; out: string }> {
  try {
    const result = await Bun.$`${cmd}`.text()
    return { ok: true, out: result.trim() }
  } catch (e: any) {
    return {
      ok: false,
      out: e?.stderr?.toString?.()?.trim() || e.message || "unknown error",
    }
  }
}

async function runInDir(
  cmd: string[],
  cwd: string,
): Promise<{ ok: boolean; out: string }> {
  try {
    const result = await Bun.$`${cmd}`.cwd(cwd).text()
    return { ok: true, out: result.trim() }
  } catch (e: any) {
    return {
      ok: false,
      out: e?.stderr?.toString?.()?.trim() || e.message || "unknown error",
    }
  }
}

function formatAge(createdAt: string): string {
  const ms = Date.now() - new Date(createdAt).getTime()
  const minutes = Math.floor(ms / 60000)
  if (minutes < 60) return `${minutes}m ago`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours}h ago`
  const days = Math.floor(hours / 24)
  return `${days}d ago`
}

// ─── Tool Exports ────────────────────────────────────────────────────

export const create = tool({
  description:
    "Create an isolated agent workspace by cloning the current repo to /tmp/agent-<name>-<hash>/. " +
    "The clone is fully independent (own .git, HEAD, index, config, hooks) and push-ready. " +
    "Uses --dissociate --reference for fast cloning with no dependency on the source repo. " +
    "Optionally creates a new branch or checks out an existing one.",
  args: {
    name: tool.schema
      .string()
      .describe(
        "Short descriptive name for the workspace (kebab-case, e.g., 'issue-42-dark-mode')",
      ),
    branch: tool.schema
      .string()
      .optional()
      .describe(
        "Branch to check out or create. If the branch exists on the remote, it is checked out. " +
        "If it does not exist, it is created from the default branch. " +
        "If omitted, the default branch is checked out.",
      ),
    base: tool.schema
      .string()
      .optional()
      .describe(
        "Base branch to create the new branch from (default: repo default branch). " +
        "Only used when creating a new branch.",
      ),
  },
  async execute(args, context) {
    const sourceDir = context.directory || "."

    // Get remote URL from the source repo
    const remoteResult = await run(["git", "-C", sourceDir, "remote", "get-url", "origin"])
    if (!remoteResult.ok) {
      return `Error: Could not get remote URL from source repo. ${remoteResult.out}`
    }
    const remoteUrl = remoteResult.out

    // Get the default branch
    const defaultBranchResult = await run([
      "gh", "repo", "view", "--json", "defaultBranchRef", "--jq", ".defaultBranchRef.name",
    ])
    const defaultBranch = defaultBranchResult.ok ? defaultBranchResult.out : "main"

    const baseBranch = args.base || defaultBranch
    const hash = generateHash()
    const wsName = args.name.replace(/[^a-z0-9-]/gi, "-").toLowerCase()
    const wsPath = `/tmp/agent-${wsName}-${hash}`

    const lines: string[] = [
      "Agent Workspace Created",
      "=======================",
      "",
    ]

    // Clone with --dissociate --reference for speed + full isolation
    const cloneResult = await run([
      "git", "clone",
      "--dissociate", "--reference", sourceDir,
      "--single-branch", "--branch", baseBranch,
      remoteUrl, wsPath,
    ])

    if (!cloneResult.ok) {
      // Fallback: try without --reference (in case of issues)
      const fallbackResult = await run([
        "git", "clone",
        "--single-branch", "--branch", baseBranch,
        remoteUrl, wsPath,
      ])
      if (!fallbackResult.ok) {
        return `Error: Could not clone repository.\n${fallbackResult.out}`
      }
      lines.push("  Clone method: direct (fallback)")
    } else {
      lines.push("  Clone method: dissociate + reference (fast)")
    }

    lines.push(`  Source: ${remoteUrl}`)
    lines.push(`  Path:   ${wsPath}`)

    // Handle branch: create new or checkout existing
    let branchName = baseBranch
    if (args.branch && args.branch !== baseBranch) {
      branchName = args.branch

      // Check if branch exists on remote
      const remoteBranchCheck = await runInDir(
        ["git", "ls-remote", "--heads", "origin", branchName],
        wsPath,
      )

      if (remoteBranchCheck.ok && remoteBranchCheck.out.includes(branchName)) {
        // Branch exists on remote — fetch and checkout
        await runInDir(["git", "fetch", "origin", branchName], wsPath)
        const checkoutResult = await runInDir(
          ["git", "checkout", "-b", branchName, `origin/${branchName}`],
          wsPath,
        )
        if (!checkoutResult.ok) {
          // Maybe it was already created by the fetch, try simple checkout
          const simpleCheckout = await runInDir(
            ["git", "checkout", branchName],
            wsPath,
          )
          if (!simpleCheckout.ok) {
            return `Error: Could not checkout existing branch '${branchName}'.\n${simpleCheckout.out}`
          }
        }
        lines.push(`  Branch: ${branchName} (checked out from remote)`)
      } else {
        // Branch does not exist — create it
        const createResult = await runInDir(
          ["git", "checkout", "-b", branchName],
          wsPath,
        )
        if (!createResult.ok) {
          return `Error: Could not create branch '${branchName}'.\n${createResult.out}`
        }
        lines.push(`  Branch: ${branchName} (created from ${baseBranch})`)
      }
    } else {
      lines.push(`  Branch: ${baseBranch} (default)`)
    }

    // Record in manifest
    const manifest = readManifest()
    manifest.workspaces.push({
      name: wsName,
      path: wsPath,
      branch: branchName,
      remoteUrl,
      sourceProject: sourceDir,
      createdAt: new Date().toISOString(),
    })
    writeManifest(manifest)

    lines.push("")
    lines.push("Workspace is ready. Pass the workspace path to git tools")
    lines.push("using the 'workspace' parameter, or use it as 'workdir' for bash commands.")
    lines.push("")
    lines.push(`workspace_path: ${wsPath}`)

    return lines.join("\n")
  },
})

export const list = tool({
  description:
    "List all active agent workspaces with their branch, age, and size.",
  args: {},
  async execute() {
    const manifest = readManifest()

    if (manifest.workspaces.length === 0) {
      return "No active agent workspaces."
    }

    // Prune workspaces that no longer exist on disk
    const alive: Workspace[] = []
    const pruned: string[] = []

    for (const ws of manifest.workspaces) {
      if (existsSync(ws.path)) {
        alive.push(ws)
      } else {
        pruned.push(ws.name)
      }
    }

    if (pruned.length > 0) {
      manifest.workspaces = alive
      writeManifest(manifest)
    }

    if (alive.length === 0) {
      return "No active agent workspaces (pruned stale manifest entries)."
    }

    const lines: string[] = [
      "Active Agent Workspaces",
      "=======================",
      "",
    ]

    for (const ws of alive) {
      // Get disk size
      const sizeResult = await run(["du", "-sh", ws.path])
      const size = sizeResult.ok ? sizeResult.out.split("\t")[0] : "unknown"

      // Get current branch in workspace
      const branchResult = await runInDir(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"],
        ws.path,
      )
      const currentBranch = branchResult.ok ? branchResult.out : ws.branch

      lines.push(`  ${ws.name}`)
      lines.push(`    Path:   ${ws.path}`)
      lines.push(`    Branch: ${currentBranch}`)
      lines.push(`    Age:    ${formatAge(ws.createdAt)}`)
      lines.push(`    Size:   ${size}`)
      lines.push("")
    }

    if (pruned.length > 0) {
      lines.push(`(Pruned ${pruned.length} stale entries: ${pruned.join(", ")})`)
    }

    lines.push(`Total: ${alive.length} workspace(s)`)

    return lines.join("\n")
  },
})

export const destroy = tool({
  description:
    "Remove an agent workspace by name. Validates the path is scoped to " +
    "/tmp/agent-* for safety. Cleans up the clone directory entirely.",
  args: {
    name: tool.schema
      .string()
      .describe("Name of the workspace to destroy"),
  },
  async execute(args) {
    const manifest = readManifest()
    const wsIndex = manifest.workspaces.findIndex(
      (w) => w.name === args.name || w.path.includes(args.name),
    )

    if (wsIndex === -1) {
      return `Workspace '${args.name}' not found in manifest. Use agent_workspace_list to see active workspaces.`
    }

    const ws = manifest.workspaces[wsIndex]

    // Safety check: ensure path is scoped to /tmp/agent-*
    if (!ws.path.startsWith("/tmp/agent-")) {
      return `SAFETY ERROR: Workspace path '${ws.path}' is not under /tmp/agent-*. Refusing to delete.`
    }

    // Remove from disk
    if (existsSync(ws.path)) {
      const result = await run(["rm", "-rf", ws.path])
      if (!result.ok) {
        return `Error removing workspace directory: ${result.out}`
      }
    }

    // Remove from manifest
    manifest.workspaces.splice(wsIndex, 1)
    writeManifest(manifest)

    return `Workspace '${ws.name}' destroyed.\n  Removed: ${ws.path}\n  Branch:  ${ws.branch}`
  },
})

export const destroy_all = tool({
  description:
    "Remove all agent workspaces. Cleans up all /tmp/agent-* directories " +
    "tracked in the manifest.",
  args: {},
  async execute() {
    const manifest = readManifest()

    if (manifest.workspaces.length === 0) {
      return "No agent workspaces to destroy."
    }

    const results: string[] = []
    let count = 0

    for (const ws of manifest.workspaces) {
      // Safety check
      if (!ws.path.startsWith("/tmp/agent-")) {
        results.push(`  SKIPPED: ${ws.name} (path not under /tmp/agent-*)`)
        continue
      }

      if (existsSync(ws.path)) {
        const result = await run(["rm", "-rf", ws.path])
        if (result.ok) {
          results.push(`  DESTROYED: ${ws.name} (${ws.path})`)
          count++
        } else {
          results.push(`  ERROR: ${ws.name} -- ${result.out}`)
        }
      } else {
        results.push(`  PRUNED: ${ws.name} (already gone)`)
        count++
      }
    }

    // Clear manifest
    manifest.workspaces = []
    writeManifest(manifest)

    return [
      "Destroy All Agent Workspaces",
      "============================",
      "",
      ...results,
      "",
      `${count} workspace(s) destroyed. Manifest cleared.`,
    ].join("\n")
  },
})
