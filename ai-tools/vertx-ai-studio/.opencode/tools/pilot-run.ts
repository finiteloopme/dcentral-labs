import { tool } from "@opencode-ai/plugin"
import { existsSync, readFileSync } from "fs"
import { join } from "path"
import { homedir } from "os"

// ─── Types ───────────────────────────────────────────────────────────

interface Workspace {
  name: string
  path: string
  projectType: string
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

function findWorkspace(name: string): Workspace | undefined {
  const manifest = readManifest()
  return manifest.workspaces.find(
    (w) => w.name === name || w.path.includes(name),
  )
}

const MAX_OUTPUT_BYTES = 10240 // 10KB

function truncate(text: string, label: string): string {
  if (text.length <= MAX_OUTPUT_BYTES) return text
  return (
    text.slice(0, MAX_OUTPUT_BYTES) +
    `\n\n... [${label} truncated at ${MAX_OUTPUT_BYTES} bytes, total ${text.length} bytes]`
  )
}

// ─── Tool Exports ────────────────────────────────────────────────────

export const execute = tool({
  description:
    "Execute a command inside a pilot workspace. The command runs with the " +
    "workspace directory as its working directory. Enforces timeout and returns " +
    "structured output with exit code, stdout, stderr, and duration.",
  args: {
    workspace: tool.schema
      .string()
      .describe("Name of the workspace to run the command in"),
    command: tool.schema
      .string()
      .describe("The shell command to execute"),
    timeout: tool.schema
      .number()
      .optional()
      .describe("Timeout in milliseconds (default: 60000)"),
  },
  async execute(args) {
    const timeout = args.timeout || 60000

    // Resolve workspace
    const ws = findWorkspace(args.workspace)
    if (!ws) {
      return `Workspace '${args.workspace}' not found. Use pilot-workspace_list to see active workspaces.`
    }

    // Safety: validate path
    if (!ws.path.startsWith("/tmp/pilot-")) {
      return `SAFETY ERROR: Workspace path '${ws.path}' is not under /tmp/pilot-*. Refusing to execute.`
    }

    // Validate workspace exists
    if (!existsSync(ws.path)) {
      return `Workspace directory '${ws.path}' does not exist. It may have been cleaned up.`
    }

    const startTime = performance.now()
    let timedOut = false

    try {
      const proc = Bun.spawn(["bash", "-c", args.command], {
        cwd: ws.path,
        stdout: "pipe",
        stderr: "pipe",
      })

      // Set up timeout
      const timeoutId = setTimeout(() => {
        timedOut = true
        proc.kill()
      }, timeout)

      // Wait for completion
      const exitCode = await proc.exited
      clearTimeout(timeoutId)

      const duration = Math.round(performance.now() - startTime)

      const stdout = await new Response(proc.stdout).text()
      const stderr = await new Response(proc.stderr).text()

      const lines: string[] = [
        "Execution Result",
        "================",
        `  Workspace: ${ws.name} (${ws.path})`,
        `  Command:   ${args.command}`,
        `  Exit Code: ${exitCode}`,
        `  Duration:  ${duration}ms`,
        `  Timed Out: ${timedOut}`,
      ]

      if (stdout.trim()) {
        lines.push("")
        lines.push("stdout:")
        lines.push("-------")
        lines.push(truncate(stdout.trim(), "stdout"))
      }

      if (stderr.trim()) {
        lines.push("")
        lines.push("stderr:")
        lines.push("-------")
        lines.push(truncate(stderr.trim(), "stderr"))
      }

      if (!stdout.trim() && !stderr.trim()) {
        lines.push("")
        lines.push("(no output)")
      }

      return lines.join("\n")
    } catch (e: any) {
      const duration = Math.round(performance.now() - startTime)

      return [
        "Execution Error",
        "===============",
        `  Workspace: ${ws.name} (${ws.path})`,
        `  Command:   ${args.command}`,
        `  Duration:  ${duration}ms`,
        `  Timed Out: ${timedOut}`,
        "",
        `Error: ${e.message || "unknown error"}`,
      ].join("\n")
    }
  },
})
