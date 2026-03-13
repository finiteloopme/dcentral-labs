import { tool } from "@opencode-ai/plugin"
import { existsSync, readFileSync, writeFileSync, mkdirSync } from "fs"
import { join } from "path"
import { homedir } from "os"
import { randomBytes } from "crypto"

// ─── Types ───────────────────────────────────────────────────────────

interface Workspace {
  name: string
  path: string
  projectType: "node" | "go" | "python" | "rust" | "generic"
  createdAt: string
  sourceProject?: string
}

interface Manifest {
  workspaces: Workspace[]
}

// ─── Helpers ─────────────────────────────────────────────────────────

function getManifestPath(): string {
  return join(homedir(), ".pilot-workspaces.json")
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
    "Create a new isolated pilot workspace in /tmp/pilot-*. " +
    "Optionally scaffold for a specific project type and copy files from the main project.",
  args: {
    name: tool.schema
      .string()
      .describe("Short descriptive name for the workspace (kebab-case)"),
    project_type: tool.schema
      .enum(["node", "go", "python", "rust", "generic"])
      .optional()
      .describe("Project type for scaffolding (default: generic)"),
    copy_files: tool.schema
      .string()
      .optional()
      .describe("Glob pattern of files to copy from the main project (e.g. 'src/**/*.ts')"),
  },
  async execute(args, context) {
    const projectType = args.project_type || "generic"
    const hash = generateHash()
    const wsName = args.name.replace(/[^a-z0-9-]/gi, "-").toLowerCase()
    const wsPath = `/tmp/pilot-${wsName}-${hash}`

    // Create workspace directory
    mkdirSync(wsPath, { recursive: true })

    const lines: string[] = [
      `Workspace created: ${wsPath}`,
      `  Name: ${wsName}`,
      `  Type: ${projectType}`,
    ]

    // Scaffold based on project type
    if (projectType === "node") {
      const result = await run(["npm", "init", "-y"])
      if (result.ok) {
        // Move package.json into workspace (npm init runs in cwd)
        try {
          await Bun.$`npm init -y`.cwd(wsPath).text()
        } catch { /* non-fatal */ }
      }
      lines.push("  Scaffolded: package.json (npm init -y)")
    } else if (projectType === "go") {
      const modName = `experiment/${wsName}`
      try {
        await Bun.$`go mod init ${modName}`.cwd(wsPath).text()
        lines.push(`  Scaffolded: go.mod (module ${modName})`)
      } catch (e: any) {
        lines.push(`  Warning: could not init go.mod: ${e.message}`)
      }
    } else if (projectType === "python") {
      try {
        await Bun.$`touch ${join(wsPath, "main.py")}`.text()
        lines.push("  Scaffolded: main.py (empty)")
      } catch { /* non-fatal */ }
    } else if (projectType === "rust") {
      try {
        await Bun.$`cargo init ${wsPath}`.text()
        lines.push("  Scaffolded: Cargo.toml + src/main.rs (cargo init)")
      } catch (e: any) {
        lines.push(`  Warning: could not cargo init: ${e.message}`)
      }
    }

    // Copy files from main project if requested
    if (args.copy_files) {
      const sourceDir = context.directory || "."
      try {
        // Use rsync or cp with glob
        const result = await run([
          "bash",
          "-c",
          `cd "${sourceDir}" && cp --parents ${args.copy_files} "${wsPath}/" 2>/dev/null || true`,
        ])
        if (result.ok) {
          lines.push(`  Copied files matching: ${args.copy_files}`)
        }
      } catch {
        lines.push(`  Warning: could not copy files matching ${args.copy_files}`)
      }
    }

    // Record in manifest
    const manifest = readManifest()
    manifest.workspaces.push({
      name: wsName,
      path: wsPath,
      projectType,
      createdAt: new Date().toISOString(),
      sourceProject: context.directory || undefined,
    })
    writeManifest(manifest)

    lines.push("")
    lines.push("Workspace is ready. Use pilot-run_execute to run commands inside it.")

    return lines.join("\n")
  },
})

export const list = tool({
  description:
    "List all active pilot workspaces with their age, size, and project type.",
  args: {},
  async execute() {
    const manifest = readManifest()

    if (manifest.workspaces.length === 0) {
      return "No active pilot workspaces."
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
      return "No active pilot workspaces (pruned stale manifest entries)."
    }

    const lines: string[] = [
      "Active Pilot Workspaces",
      "=======================",
      "",
    ]

    for (const ws of alive) {
      // Get disk size
      const sizeResult = await run(["du", "-sh", ws.path])
      const size = sizeResult.ok
        ? sizeResult.out.split("\t")[0]
        : "unknown"

      lines.push(`  ${ws.name}`)
      lines.push(`    Path: ${ws.path}`)
      lines.push(`    Type: ${ws.projectType}`)
      lines.push(`    Age:  ${formatAge(ws.createdAt)}`)
      lines.push(`    Size: ${size}`)
      lines.push("")
    }

    if (pruned.length > 0) {
      lines.push(`(Pruned ${pruned.length} stale entries: ${pruned.join(", ")})`)
    }

    lines.push(`Total: ${alive.length} workspace(s)`)

    return lines.join("\n")
  },
})

export const inspect = tool({
  description:
    "Show details of a specific pilot workspace including file tree and status.",
  args: {
    name: tool.schema
      .string()
      .describe("Name of the workspace to inspect"),
  },
  async execute(args) {
    const manifest = readManifest()
    const ws = manifest.workspaces.find(
      (w) => w.name === args.name || w.path.includes(args.name),
    )

    if (!ws) {
      return `Workspace '${args.name}' not found. Use pilot-workspace_list to see active workspaces.`
    }

    if (!existsSync(ws.path)) {
      return `Workspace '${args.name}' directory no longer exists at ${ws.path}. It may have been cleaned up externally.`
    }

    const lines: string[] = [
      `Workspace: ${ws.name}`,
      `=======================`,
      `  Path:    ${ws.path}`,
      `  Type:    ${ws.projectType}`,
      `  Created: ${ws.createdAt}`,
      `  Age:     ${formatAge(ws.createdAt)}`,
    ]

    if (ws.sourceProject) {
      lines.push(`  Source:  ${ws.sourceProject}`)
    }

    // Disk size
    const sizeResult = await run(["du", "-sh", ws.path])
    if (sizeResult.ok) {
      lines.push(`  Size:    ${sizeResult.out.split("\t")[0]}`)
    }

    lines.push("")
    lines.push("File Tree:")
    lines.push("----------")

    // File tree (prefer tree, fallback to find)
    const treeResult = await run(["tree", "-L", "3", "--noreport", ws.path])
    if (treeResult.ok) {
      lines.push(treeResult.out)
    } else {
      const findResult = await run([
        "find",
        ws.path,
        "-maxdepth",
        "3",
        "-not",
        "-path",
        "*/node_modules/*",
        "-not",
        "-path",
        "*/.git/*",
        "-not",
        "-path",
        "*/target/*",
      ])
      if (findResult.ok) {
        lines.push(findResult.out)
      } else {
        lines.push("  (could not list files)")
      }
    }

    return lines.join("\n")
  },
})

export const destroy = tool({
  description:
    "Remove a pilot workspace by name. Validates the path is scoped to /tmp/pilot-* for safety.",
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
      return `Workspace '${args.name}' not found in manifest. Use pilot-workspace_list to see active workspaces.`
    }

    const ws = manifest.workspaces[wsIndex]

    // Safety check: ensure path is scoped to /tmp/pilot-*
    if (!ws.path.startsWith("/tmp/pilot-")) {
      return `SAFETY ERROR: Workspace path '${ws.path}' is not under /tmp/pilot-*. Refusing to delete.`
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

    return `Workspace '${ws.name}' destroyed.\n  Removed: ${ws.path}`
  },
})

export const destroy_all = tool({
  description:
    "Remove all pilot workspaces. Cleans up all /tmp/pilot-* directories tracked in the manifest.",
  args: {},
  async execute() {
    const manifest = readManifest()

    if (manifest.workspaces.length === 0) {
      return "No pilot workspaces to destroy."
    }

    const results: string[] = []
    let count = 0

    for (const ws of manifest.workspaces) {
      // Safety check
      if (!ws.path.startsWith("/tmp/pilot-")) {
        results.push(`  SKIPPED: ${ws.name} (path not under /tmp/pilot-*)`)
        continue
      }

      if (existsSync(ws.path)) {
        const result = await run(["rm", "-rf", ws.path])
        if (result.ok) {
          results.push(`  DESTROYED: ${ws.name} (${ws.path})`)
          count++
        } else {
          results.push(`  ERROR: ${ws.name} — ${result.out}`)
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
      "Destroy All Workspaces",
      "======================",
      "",
      ...results,
      "",
      `${count} workspace(s) destroyed. Manifest cleared.`,
    ].join("\n")
  },
})
