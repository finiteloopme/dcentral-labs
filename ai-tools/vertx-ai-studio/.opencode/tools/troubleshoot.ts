import { tool } from "@opencode-ai/plugin"
import { existsSync, readdirSync, readFileSync, statSync } from "fs"
import { join } from "path"

// ─── Shared Helpers ─────────────────────────────────────────────────

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

// ─── System Diagnostics ─────────────────────────────────────────────

export const check_ports = tool({
  description:
    "Check which ports are listening on the local system. " +
    "Useful for diagnosing port conflicts or verifying services are running.",
  args: {
    port: tool.schema
      .number()
      .optional()
      .describe("Check a specific port number"),
  },
  async execute(args) {
    if (args.port) {
      const result = await run(["ss", "-tlnp", `sport = :${args.port}`])
      if (!result.ok) return `Error checking port ${args.port}: ${result.out}`
      return result.out || `Port ${args.port} is not in use.`
    }

    const result = await run(["ss", "-tlnp"])
    if (!result.ok) return `Error listing ports: ${result.out}`
    return result.out || "No listening ports found."
  },
})

export const check_dns = tool({
  description:
    "Perform DNS lookup for a hostname. Shows resolved addresses and records.",
  args: {
    hostname: tool.schema.string().describe("Hostname to resolve"),
    type: tool.schema
      .string()
      .optional()
      .describe("Record type (A, AAAA, CNAME, MX, TXT, NS, etc.)"),
  },
  async execute(args) {
    const flags: string[] = ["dig", "+short"]
    if (args.type) flags.push(args.type)
    flags.push(args.hostname)

    const result = await run(flags)
    if (!result.ok) {
      // Fallback to nslookup
      const fallback = await run(["nslookup", args.hostname])
      if (!fallback.ok) return `Error resolving ${args.hostname}: ${fallback.out}`
      return fallback.out
    }

    return result.out || `No ${args.type || "A"} records found for ${args.hostname}.`
  },
})

export const check_connectivity = tool({
  description:
    "Check network connectivity to a host. Uses curl for HTTP(S) endpoints " +
    "and ping for general hosts.",
  args: {
    host: tool.schema.string().describe("Host or URL to check connectivity to"),
    timeout: tool.schema
      .number()
      .optional()
      .describe("Timeout in seconds (default: 5)"),
  },
  async execute(args) {
    const timeout = args.timeout || 5

    if (args.host.startsWith("http://") || args.host.startsWith("https://")) {
      // HTTP(S) check
      const result = await run([
        "curl",
        "-sS",
        "-o",
        "/dev/null",
        "-w",
        "HTTP %{http_code} | Time: %{time_total}s | DNS: %{time_namelookup}s | Connect: %{time_connect}s",
        "--max-time",
        String(timeout),
        args.host,
      ])
      if (!result.ok) return `FAIL: Cannot reach ${args.host}. Error: ${result.out}`
      return `PASS: ${args.host}\n  ${result.out}`
    }

    // Ping check
    const result = await run(["ping", "-c", "3", "-W", String(timeout), args.host])
    if (!result.ok) return `FAIL: Cannot reach ${args.host}. Error: ${result.out}`
    return result.out
  },
})

export const system_info = tool({
  description:
    "Show system information including OS, kernel, CPU, memory, and uptime.",
  args: {},
  async execute() {
    const lines: string[] = ["System Information", "==================", ""]

    // OS / Kernel
    const uname = await run(["uname", "-a"])
    if (uname.ok) lines.push(`Kernel : ${uname.out}`)

    // CPU
    try {
      const cpu = await Bun.$`grep -m1 "model name" /proc/cpuinfo`.text()
      const cpuName = cpu.trim().split(":")[1]?.trim() || "unknown"
      const cores = await Bun.$`grep -c "^processor" /proc/cpuinfo`.text()
      lines.push(`CPU    : ${cpuName} (${cores.trim()} cores)`)
    } catch {
      lines.push("CPU    : could not detect")
    }

    // Memory
    const free = await run(["free", "-h"])
    if (free.ok) {
      const memLine = free.out.split("\n").find((l) => l.startsWith("Mem:"))
      if (memLine) {
        const parts = memLine.split(/\s+/)
        lines.push(`Memory : ${parts[2]} used / ${parts[1]} total (${parts[6]} available)`)
      }
    }

    // Disk
    const df = await run(["df", "-h", "/"])
    if (df.ok) {
      const diskLine = df.out.split("\n")[1]
      if (diskLine) {
        const parts = diskLine.split(/\s+/)
        lines.push(`Disk / : ${parts[2]} used / ${parts[1]} total (${parts[4]} usage)`)
      }
    }

    // Uptime
    try {
      const uptime = await Bun.$`uptime -p`.text()
      lines.push(`Uptime : ${uptime.trim()}`)
    } catch {}

    return lines.join("\n")
  },
})

export const process_list = tool({
  description:
    "List running processes, optionally filtered by name or sorted by resource usage.",
  args: {
    filter: tool.schema
      .string()
      .optional()
      .describe("Filter processes by name (grep pattern)"),
    sort: tool.schema
      .enum(["cpu", "mem", "pid"])
      .optional()
      .describe("Sort by resource (default: cpu)"),
    limit: tool.schema
      .number()
      .optional()
      .describe("Max number of processes to show (default: 20)"),
  },
  async execute(args) {
    const limit = args.limit || 20
    const sort = args.sort || "cpu"

    let sortFlag: string
    switch (sort) {
      case "mem":
        sortFlag = "-rss"
        break
      case "pid":
        sortFlag = "pid"
        break
      default:
        sortFlag = "-pcpu"
    }

    if (args.filter) {
      const result = await run([
        "ps",
        "aux",
        "--sort",
        sortFlag,
      ])
      if (!result.ok) return `Error listing processes: ${result.out}`

      const lines = result.out.split("\n")
      const header = lines[0]
      const filtered = lines
        .slice(1)
        .filter((l) => l.toLowerCase().includes(args.filter!.toLowerCase()))
        .slice(0, limit)

      if (filtered.length === 0) {
        return `No processes found matching '${args.filter}'.`
      }

      return [header, ...filtered].join("\n")
    }

    const result = await run(["ps", "aux", "--sort", sortFlag])
    if (!result.ok) return `Error listing processes: ${result.out}`

    const lines = result.out.split("\n")
    return lines.slice(0, limit + 1).join("\n")
  },
})

export const disk_usage = tool({
  description: "Show disk usage for a directory or the entire filesystem.",
  args: {
    path: tool.schema
      .string()
      .optional()
      .describe("Directory path to check (default: current directory)"),
    depth: tool.schema
      .number()
      .optional()
      .describe("Max depth for directory breakdown (default: 1)"),
  },
  async execute(args) {
    const target = args.path || "."
    const depth = args.depth || 1

    const result = await run([
      "du",
      "-h",
      "--max-depth",
      String(depth),
      "--apparent-size",
      target,
    ])
    if (!result.ok) return `Error checking disk usage: ${result.out}`
    return result.out
  },
})

export const container_health = tool({
  description:
    "Check health of running containers. Lists containers with their " +
    "status, resource usage, and health check results.",
  args: {},
  async execute() {
    // Check if podman is available
    const podmanCheck = await run(["podman", "--version"])
    if (!podmanCheck.ok) {
      return "Error: podman is not installed or not in PATH."
    }

    const lines: string[] = ["Container Health Check", "=====================", ""]

    // List running containers
    const ps = await run([
      "podman",
      "ps",
      "--format",
      "json",
    ])

    if (!ps.ok) {
      return `Error listing containers: ${ps.out}`
    }

    try {
      const containers = JSON.parse(ps.out)
      if (!containers || containers.length === 0) {
        return "No running containers found."
      }

      for (const c of containers) {
        const name = c.Names?.[0] || c.Name || c.Id?.slice(0, 12) || "unknown"
        const image = c.Image || "unknown"
        const state = c.State || "unknown"
        const status = c.Status || ""

        lines.push(`Container: ${name}`)
        lines.push(`  Image  : ${image}`)
        lines.push(`  State  : ${state}`)
        lines.push(`  Status : ${status}`)

        // Get resource stats
        const stats = await run([
          "podman",
          "stats",
          "--no-stream",
          "--format",
          "{{.CPUPerc}} CPU | {{.MemUsage}} MEM | {{.NetIO}} NET | {{.BlockIO}} BLOCK",
          name,
        ])
        if (stats.ok && stats.out) {
          lines.push(`  Usage  : ${stats.out}`)
        }

        lines.push("")
      }
    } catch {
      lines.push("Could not parse container list.")
      lines.push(ps.out)
    }

    return lines.join("\n")
  },
})

// ─── Log Analysis Helpers ───────────────────────────────────────────

type SourceType = "file" | "container" | "cloudbuild" | "journald" | "gcloud"

function inferSource(target: string): SourceType {
  if (target.includes("/") || target.endsWith(".log") || target.endsWith(".txt")) return "file"
  if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(target)) return "cloudbuild"
  if (target.endsWith(".service")) return "journald"
  return "container"
}

const SEVERITY_PATTERNS: Record<string, RegExp> = {
  error: /\b(ERROR|FATAL|CRIT(?:ICAL)?|PANIC|EXCEPTION|FAIL(?:ED|URE)?|Traceback|panic:|fatal error:|UnhandledPromiseRejection|ECONNREFUSED|OOMKilled|segfault|SIGSEGV|SIGKILL)\b/i,
  warning: /\b(WARN(?:ING)?|DEPRECAT(?:ED|ION)|TIMEOUT|RETRY|retry|timeout)\b/i,
  info: /\b(INFO|DEBUG|TRACE|NOTICE)\b/i,
}

function matchesSeverity(line: string, minSeverity: string): boolean {
  if (minSeverity === "all") return true
  if (minSeverity === "info") return true
  if (minSeverity === "warning") {
    return SEVERITY_PATTERNS.error.test(line) || SEVERITY_PATTERNS.warning.test(line)
  }
  if (minSeverity === "error") {
    return SEVERITY_PATTERNS.error.test(line)
  }
  return true
}

function extractWithContext(lines: string[], pattern: RegExp, contextLines: number = 5): string[] {
  const result: string[] = []
  const matched = new Set<number>()

  for (let i = 0; i < lines.length; i++) {
    if (pattern.test(lines[i])) {
      matched.add(i)
    }
  }

  for (const idx of matched) {
    const start = Math.max(0, idx - contextLines)
    const end = Math.min(lines.length - 1, idx + contextLines)
    if (result.length > 0) result.push("---")
    for (let i = start; i <= end; i++) {
      const marker = matched.has(i) ? ">>> " : "    "
      result.push(`${marker}${i + 1}: ${lines[i]}`)
    }
  }

  return result
}

// ─── Log Analysis Tools ─────────────────────────────────────────────

export const discover_sources = tool({
  description:
    "Auto-detect available log sources in the current project. " +
    "Checks for local log files in logs/, running containers, " +
    "recent Cloud Build builds, and common log file patterns.",
  args: {},
  async execute(_args, context) {
    const root = context.directory || "."
    const sources: string[] = ["Log Source Discovery", "====================", ""]

    // 1. Check logs/ directory (scaffolded per-run logs)
    const logsDir = join(root, "logs")
    if (existsSync(logsDir)) {
      try {
        const files = readdirSync(logsDir)
          .filter((f) => f.endsWith(".log"))
          .sort()
          .reverse()
          .slice(0, 10)
        if (files.length > 0) {
          sources.push("── Local Log Files (logs/) ──")
          for (const f of files) {
            const stat = statSync(join(logsDir, f))
            const age = Math.round((Date.now() - stat.mtimeMs) / 60000)
            const size = stat.size > 1024 ? `${(stat.size / 1024).toFixed(1)}KB` : `${stat.size}B`
            sources.push(`  ${f}  (${age}m ago, ${size})`)
          }
          sources.push("")
        }
      } catch { /* non-fatal */ }
    }

    // 2. Check for *.log files in project root
    try {
      const rootFiles = readdirSync(root).filter(
        (f) => f.endsWith(".log") && statSync(join(root, f)).isFile(),
      )
      if (rootFiles.length > 0) {
        sources.push("── Log Files (project root) ──")
        for (const f of rootFiles) {
          const stat = statSync(join(root, f))
          const size = stat.size > 1024 ? `${(stat.size / 1024).toFixed(1)}KB` : `${stat.size}B`
          sources.push(`  ${f}  (${size})`)
        }
        sources.push("")
      }
    } catch { /* non-fatal */ }

    // 3. Check running containers
    const podmanCheck = await run(["podman", "ps", "--format", "{{.Names}}\t{{.Image}}\t{{.Status}}"])
    if (podmanCheck.ok && podmanCheck.out) {
      sources.push("── Containers (Podman) ──")
      for (const line of podmanCheck.out.split("\n")) {
        if (line.trim()) sources.push(`  ${line}`)
      }
      sources.push("")
    }

    // Also check stopped containers
    const podmanAll = await run(["podman", "ps", "-a", "--filter", "status=exited", "--format", "{{.Names}}\t{{.Image}}\t{{.Status}}"])
    if (podmanAll.ok && podmanAll.out) {
      sources.push("── Stopped Containers ──")
      for (const line of podmanAll.out.split("\n")) {
        if (line.trim()) sources.push(`  ${line}`)
      }
      sources.push("")
    }

    // 4. Check recent Cloud Build builds
    const gcloudCheck = await run(["gcloud", "builds", "list", "--limit=5", "--format=table(id,status,createTime,duration)"])
    if (gcloudCheck.ok && gcloudCheck.out) {
      sources.push("── Cloud Build (recent) ──")
      sources.push(gcloudCheck.out)
      sources.push("")
    }

    // 5. Check for common log directories
    const commonDirs = ["/var/log", "var/log", "log"]
    for (const dir of commonDirs) {
      const fullPath = dir.startsWith("/") ? dir : join(root, dir)
      if (existsSync(fullPath)) {
        try {
          const files = readdirSync(fullPath)
            .filter((f) => f.endsWith(".log"))
            .slice(0, 5)
          if (files.length > 0) {
            sources.push(`── ${fullPath} ──`)
            for (const f of files) sources.push(`  ${f}`)
            sources.push("")
          }
        } catch { /* permission denied is common */ }
      }
    }

    if (sources.length <= 3) {
      sources.push("No log sources found. Run a build or deployment to generate logs.")
      sources.push("")
      sources.push("Tip: If this project was scaffolded with lib-agents, logs are")
      sources.push("captured automatically in the logs/ directory.")
    }

    return sources.join("\n")
  },
})

export const read_logs = tool({
  description:
    "Read and filter logs from various sources (file, container, Cloud Build, " +
    "journald, Cloud Logging). Supports severity filtering, time windowing, " +
    "search patterns, and smart truncation. Source type is auto-detected " +
    "from the target if not specified.",
  args: {
    source: tool.schema
      .enum(["auto", "file", "container", "cloudbuild", "journald", "gcloud"])
      .optional()
      .describe("Log source type (default: auto-detect from target)"),
    target: tool.schema
      .string()
      .describe(
        "Source identifier: file path, container name/ID, Cloud Build ID, " +
        "systemd unit name, or Cloud Logging filter",
      ),
    severity: tool.schema
      .enum(["all", "info", "warning", "error"])
      .optional()
      .describe("Minimum severity to include (default: all)"),
    since: tool.schema
      .string()
      .optional()
      .describe("Time window: '10m', '1h', '1d' (default: 1h)"),
    tail: tool.schema
      .number()
      .optional()
      .describe("Number of lines from end (default: 500)"),
    search: tool.schema
      .string()
      .optional()
      .describe("Search pattern to filter lines (regex supported)"),
  },
  async execute(args) {
    const sourceType = args.source === "auto" || !args.source
      ? inferSource(args.target)
      : args.source as SourceType
    const severity = args.severity || "all"
    const tail = args.tail || 500
    const since = args.since || "1h"

    let rawLines: string[] = []

    switch (sourceType) {
      case "file": {
        if (!existsSync(args.target)) {
          return `Error: File not found: ${args.target}`
        }
        try {
          const content = readFileSync(args.target, "utf-8")
          rawLines = content.split("\n")
        } catch (e: any) {
          return `Error reading file: ${e.message}`
        }
        break
      }

      case "container": {
        const flags = ["logs", "--tail", String(tail)]
        if (since) flags.push("--since", since)
        flags.push(args.target)
        const result = await run(["podman", ...flags])
        if (!result.ok) return `Error reading container logs: ${result.out}`
        rawLines = result.out.split("\n")
        break
      }

      case "cloudbuild": {
        const result = await run(["gcloud", "builds", "log", args.target])
        if (!result.ok) return `Error reading Cloud Build logs: ${result.out}`
        rawLines = result.out.split("\n")
        break
      }

      case "journald": {
        const flags = ["journalctl", "-u", args.target, "--no-pager", "-n", String(tail)]
        if (since) flags.push("--since", since)
        const result = await run(flags)
        if (!result.ok) return `Error reading journald logs: ${result.out}`
        rawLines = result.out.split("\n")
        break
      }

      case "gcloud": {
        const flags = ["gcloud", "logging", "read", args.target, "--limit", String(tail), "--format=value(textPayload)"]
        const result = await run(flags)
        if (!result.ok) return `Error reading Cloud Logging: ${result.out}`
        rawLines = result.out.split("\n")
        break
      }
    }

    // Apply severity filter
    let filtered = severity === "all"
      ? rawLines
      : rawLines.filter((line) => matchesSeverity(line, severity))

    // Apply search pattern
    if (args.search) {
      try {
        const regex = new RegExp(args.search, "i")
        filtered = filtered.filter((line) => regex.test(line))
      } catch {
        return `Error: Invalid search pattern: ${args.search}`
      }
    }

    // Apply tail limit
    if (filtered.length > tail) {
      filtered = filtered.slice(-tail)
    }

    const header = [
      `Log: ${args.target} (${sourceType})`,
      `Lines: ${filtered.length} (of ${rawLines.length} total)`,
      `Severity: ${severity} | Since: ${since} | Tail: ${tail}`,
      args.search ? `Search: ${args.search}` : null,
      "\u2500".repeat(60),
    ]
      .filter(Boolean)
      .join("\n")

    return `${header}\n${filtered.join("\n")}`
  },
})

export const extract_errors = tool({
  description:
    "Extract errors and warnings from logs with surrounding context. " +
    "Detects stack traces, ERROR/FATAL/WARN messages, exit codes, panics, " +
    "and other common error patterns. Returns only relevant sections.",
  args: {
    source: tool.schema
      .enum(["auto", "file", "container", "cloudbuild", "journald", "gcloud"])
      .optional()
      .describe("Log source type (default: auto-detect from target)"),
    target: tool.schema
      .string()
      .describe("Source identifier: file path, container name, build ID, etc."),
    context_lines: tool.schema
      .number()
      .optional()
      .describe("Lines of context around each error (default: 5)"),
    severity: tool.schema
      .enum(["error", "warning"])
      .optional()
      .describe("Minimum severity to extract (default: error)"),
  },
  async execute(args) {
    const sourceType = args.source === "auto" || !args.source
      ? inferSource(args.target)
      : args.source as SourceType
    const contextLines = args.context_lines || 5
    const severity = args.severity || "error"

    // Read the log content
    let rawContent: string

    switch (sourceType) {
      case "file": {
        if (!existsSync(args.target)) {
          return `Error: File not found: ${args.target}`
        }
        try {
          rawContent = readFileSync(args.target, "utf-8")
        } catch (e: any) {
          return `Error reading file: ${e.message}`
        }
        break
      }

      case "container": {
        const result = await run(["podman", "logs", "--tail", "2000", args.target])
        if (!result.ok) return `Error reading container logs: ${result.out}`
        rawContent = result.out
        break
      }

      case "cloudbuild": {
        const result = await run(["gcloud", "builds", "log", args.target])
        if (!result.ok) return `Error reading Cloud Build logs: ${result.out}`
        rawContent = result.out
        break
      }

      case "journald": {
        const result = await run(["journalctl", "-u", args.target, "--no-pager", "-n", "2000"])
        if (!result.ok) return `Error reading journald logs: ${result.out}`
        rawContent = result.out
        break
      }

      case "gcloud": {
        const result = await run(["gcloud", "logging", "read", args.target, "--limit=2000", "--format=value(textPayload)"])
        if (!result.ok) return `Error reading Cloud Logging: ${result.out}`
        rawContent = result.out
        break
      }

      default:
        return `Error: Unknown source type: ${sourceType}`
    }

    const lines = rawContent.split("\n")
    const pattern = severity === "warning"
      ? new RegExp(`${SEVERITY_PATTERNS.error.source}|${SEVERITY_PATTERNS.warning.source}`, "i")
      : SEVERITY_PATTERNS.error

    const extracted = extractWithContext(lines, pattern, contextLines)

    if (extracted.length === 0) {
      return `No ${severity}-level messages found in ${args.target} (${sourceType}).`
    }

    const errorCount = extracted.filter((l) => l.startsWith(">>>")).length
    const header = [
      `Error Extraction: ${args.target} (${sourceType})`,
      `Found: ${errorCount} ${severity}-level messages`,
      `Context: \u00b1${contextLines} lines`,
      "\u2500".repeat(60),
    ].join("\n")

    return `${header}\n${extracted.join("\n")}`
  },
})

export const compare_logs = tool({
  description:
    "Compare logs between two runs to identify what changed. " +
    "Useful for diagnosing regressions: compare a working build/run " +
    "against a failing one. Highlights lines present in the failing " +
    "run but absent from the working run.",
  args: {
    source: tool.schema
      .enum(["auto", "file", "container", "cloudbuild"])
      .optional()
      .describe("Log source type (default: auto-detect from target)"),
    good: tool.schema
      .string()
      .describe("Identifier for the working/good run (file path, container, build ID)"),
    bad: tool.schema
      .string()
      .describe("Identifier for the failing/bad run (file path, container, build ID)"),
    context_lines: tool.schema
      .number()
      .optional()
      .describe("Lines of context around differences (default: 3)"),
  },
  async execute(args) {
    const contextLines = args.context_lines || 3

    async function fetchContent(target: string): Promise<string> {
      const sourceType = args.source === "auto" || !args.source
        ? inferSource(target)
        : args.source as SourceType

      switch (sourceType) {
        case "file": {
          if (!existsSync(target)) throw new Error(`File not found: ${target}`)
          return readFileSync(target, "utf-8")
        }
        case "container": {
          const result = await run(["podman", "logs", "--tail", "2000", target])
          if (!result.ok) throw new Error(`Container logs error: ${result.out}`)
          return result.out
        }
        case "cloudbuild": {
          const result = await run(["gcloud", "builds", "log", target])
          if (!result.ok) throw new Error(`Cloud Build logs error: ${result.out}`)
          return result.out
        }
        default:
          throw new Error(`Compare not supported for source type: ${sourceType}`)
      }
    }

    let goodContent: string
    let badContent: string

    try {
      goodContent = await fetchContent(args.good)
    } catch (e: any) {
      return `Error reading good run: ${e.message}`
    }

    try {
      badContent = await fetchContent(args.bad)
    } catch (e: any) {
      return `Error reading bad run: ${e.message}`
    }

    // Normalize lines: strip leading timestamps for comparison
    const timestampRegex = /^\d{4}[-/]\d{2}[-/]\d{2}[T ]\d{2}:\d{2}:\d{2}[.\d]*\s*/
    const normalize = (line: string) => line.replace(timestampRegex, "").trim()

    const goodLines = goodContent.split("\n")
    const badLines = badContent.split("\n")

    const goodSet = new Set(goodLines.map(normalize))
    const badSet = new Set(badLines.map(normalize))

    // Find lines unique to bad (potential issues)
    const onlyInBad: { idx: number; line: string }[] = []
    for (let i = 0; i < badLines.length; i++) {
      if (!goodSet.has(normalize(badLines[i])) && badLines[i].trim()) {
        onlyInBad.push({ idx: i, line: badLines[i] })
      }
    }

    // Find lines unique to good (things that stopped happening)
    const onlyInGood: { idx: number; line: string }[] = []
    for (let i = 0; i < goodLines.length; i++) {
      if (!badSet.has(normalize(goodLines[i])) && goodLines[i].trim()) {
        onlyInGood.push({ idx: i, line: goodLines[i] })
      }
    }

    const result: string[] = [
      "Log Comparison",
      "==============",
      `Good: ${args.good} (${goodLines.length} lines)`,
      `Bad:  ${args.bad} (${badLines.length} lines)`,
      "\u2500".repeat(60),
      "",
    ]

    if (onlyInBad.length > 0) {
      result.push(`\u2500\u2500 Lines ONLY in failing run (${onlyInBad.length}) \u2500\u2500`)
      result.push("These appeared in the bad run but not the good run:")
      result.push("")
      for (const entry of onlyInBad.slice(0, 50)) {
        // Add context from bad run
        const start = Math.max(0, entry.idx - contextLines)
        const end = Math.min(badLines.length - 1, entry.idx + contextLines)
        for (let i = start; i <= end; i++) {
          const marker = i === entry.idx ? "+ " : "  "
          result.push(`${marker}${i + 1}: ${badLines[i]}`)
        }
        result.push("")
      }
      if (onlyInBad.length > 50) {
        result.push(`  ... and ${onlyInBad.length - 50} more unique lines`)
      }
    }

    if (onlyInGood.length > 0) {
      result.push("")
      result.push(`\u2500\u2500 Lines ONLY in working run (${onlyInGood.length}) \u2500\u2500`)
      result.push("These were present in the good run but missing from the bad run:")
      result.push("")
      for (const entry of onlyInGood.slice(0, 20)) {
        result.push(`- ${entry.idx + 1}: ${entry.line}`)
      }
      if (onlyInGood.length > 20) {
        result.push(`  ... and ${onlyInGood.length - 20} more`)
      }
    }

    if (onlyInBad.length === 0 && onlyInGood.length === 0) {
      result.push("No significant differences found between the two runs.")
      result.push("The logs appear identical (after timestamp normalization).")
    }

    return result.join("\n")
  },
})

// ─── Prometheus Helpers ─────────────────────────────────────────────

async function findPrometheusEndpoint(context?: { directory?: string }): Promise<{ url: string; method: string } | null> {
  // 1. Check PROMETHEUS_URL environment variable
  const envUrl = process.env.PROMETHEUS_URL
  if (envUrl) {
    return { url: envUrl.replace(/\/+$/, ""), method: "PROMETHEUS_URL env var" }
  }

  const root = context?.directory || "."

  // 2. Scan for compose files with prometheus service
  const composeFiles = [
    "docker-compose.yml",
    "docker-compose.yaml",
    "podman-compose.yml",
    "compose.yml",
    "compose.yaml",
  ]
  for (const file of composeFiles) {
    const fullPath = join(root, file)
    if (existsSync(fullPath)) {
      try {
        const content = readFileSync(fullPath, "utf-8")
        // Look for prometheus service with port mapping
        const promMatch = content.match(/prometheus[\s\S]*?ports:\s*\n\s*-\s*["']?(\d+):(\d+)["']?/i)
        if (promMatch) {
          const hostPort = promMatch[1]
          return { url: `http://localhost:${hostPort}`, method: `${file} (port ${hostPort})` }
        }
      } catch { /* non-fatal */ }
    }
  }

  // 3. Check running podman containers with "prometheus" in image name
  const podmanCheck = await run(["podman", "ps", "--format", "json"])
  if (podmanCheck.ok && podmanCheck.out) {
    try {
      const containers = JSON.parse(podmanCheck.out)
      for (const c of containers) {
        const image = (c.Image || "").toLowerCase()
        if (image.includes("prometheus")) {
          // Extract host port mapping
          const ports = c.Ports || []
          for (const p of ports) {
            if (p.host_port && p.container_port === 9090) {
              return { url: `http://localhost:${p.host_port}`, method: `podman container (${c.Names?.[0] || c.Id?.slice(0, 12)})` }
            }
          }
          // Default prometheus port
          return { url: "http://localhost:9090", method: `podman container (${c.Names?.[0] || c.Id?.slice(0, 12)})` }
        }
      }
    } catch { /* non-fatal */ }
  }

  // 4. Try localhost:9090 as fallback
  try {
    const resp = await fetch("http://localhost:9090/-/ready", { signal: AbortSignal.timeout(3000) })
    if (resp.ok) {
      return { url: "http://localhost:9090", method: "localhost:9090 (auto-detected)" }
    }
  } catch { /* not running */ }

  return null
}

function parseDuration(duration: string): number {
  const match = duration.match(/^(\d+(?:\.\d+)?)\s*(s|m|h|d|w)$/)
  if (!match) return 0
  const value = parseFloat(match[1])
  switch (match[2]) {
    case "s": return value * 1000
    case "m": return value * 60 * 1000
    case "h": return value * 3600 * 1000
    case "d": return value * 86400 * 1000
    case "w": return value * 604800 * 1000
    default: return 0
  }
}

function formatPromResult(data: any): string {
  if (!data || !data.data) return "No data returned."

  const resultType = data.data.resultType
  const results = data.data.result

  if (!results || results.length === 0) return "Query returned no results."

  const lines: string[] = [`Result type: ${resultType}`, ""]

  switch (resultType) {
    case "vector": {
      for (const r of results) {
        const labels = Object.entries(r.metric || {})
          .map(([k, v]) => `${k}="${v}"`)
          .join(", ")
        const [timestamp, value] = r.value || []
        const time = timestamp ? new Date(timestamp * 1000).toISOString() : "?"
        lines.push(`{${labels}} => ${value}  (@ ${time})`)
      }
      break
    }

    case "scalar": {
      const [timestamp, value] = results
      lines.push(`Scalar: ${value}  (@ ${new Date(timestamp * 1000).toISOString()})`)
      break
    }

    case "matrix": {
      for (const r of results) {
        const labels = Object.entries(r.metric || {})
          .map(([k, v]) => `${k}="${v}"`)
          .join(", ")
        lines.push(`{${labels}}`)
        lines.push("  Timestamp              | Value")
        lines.push("  " + "\u2500".repeat(50))
        for (const [ts, val] of r.values || []) {
          lines.push(`  ${new Date(ts * 1000).toISOString()} | ${val}`)
        }
        lines.push("")
      }
      break
    }

    case "string": {
      lines.push(`String: ${results}`)
      break
    }

    default:
      lines.push(JSON.stringify(results, null, 2))
  }

  return lines.join("\n")
}

// ─── Prometheus Tools ───────────────────────────────────────────────

export const discover_prometheus = tool({
  description:
    "Auto-detect a Prometheus endpoint. Checks PROMETHEUS_URL env var, " +
    "docker-compose/podman-compose files, running containers, and " +
    "localhost:9090 as fallback. Returns the discovered endpoint or " +
    "suggestions if not found.",
  args: {},
  async execute(_args, context) {
    const result = await findPrometheusEndpoint(context)

    if (result) {
      const lines = [
        "Prometheus Discovery",
        "====================",
        "",
        `Endpoint : ${result.url}`,
        `Found via: ${result.method}`,
        "",
        "Ready for queries. Use query_metrics or check_targets.",
      ]
      return lines.join("\n")
    }

    return [
      "Prometheus Discovery",
      "====================",
      "",
      "No Prometheus endpoint found.",
      "",
      "Checked:",
      "  1. PROMETHEUS_URL environment variable — not set",
      "  2. docker-compose.yml / podman-compose.yml — no prometheus service found",
      "  3. Running podman containers — no prometheus image detected",
      "  4. http://localhost:9090 — not reachable",
      "",
      "To connect Prometheus:",
      "  - Set PROMETHEUS_URL=http://<host>:<port>",
      "  - Or start Prometheus: podman run -d -p 9090:9090 prom/prometheus",
      "  - Or add a prometheus service to your compose file",
    ].join("\n")
  },
})

export const query_metrics = tool({
  description:
    "Execute a PromQL instant query against Prometheus. Returns current " +
    "metric values. Use for point-in-time checks like current CPU usage, " +
    "memory pressure, or error rates.",
  args: {
    query: tool.schema
      .string()
      .describe("PromQL query expression (e.g. 'up', 'rate(http_requests_total[5m])')"),
    endpoint: tool.schema
      .string()
      .optional()
      .describe("Prometheus endpoint URL (auto-detected if not specified)"),
    time: tool.schema
      .string()
      .optional()
      .describe("Evaluation timestamp (RFC3339 or Unix timestamp, default: now)"),
    timeout: tool.schema
      .string()
      .optional()
      .describe("Query timeout (e.g. '30s', default: server default)"),
  },
  async execute(args, context) {
    let endpoint = args.endpoint
    if (!endpoint) {
      const discovered = await findPrometheusEndpoint(context)
      if (!discovered) {
        return "Error: No Prometheus endpoint found. Set PROMETHEUS_URL or pass endpoint parameter."
      }
      endpoint = discovered.url
    }

    const params = new URLSearchParams({ query: args.query })
    if (args.time) params.set("time", args.time)
    if (args.timeout) params.set("timeout", args.timeout)

    const url = `${endpoint}/api/v1/query?${params.toString()}`

    try {
      const resp = await fetch(url, { signal: AbortSignal.timeout(30000) })
      if (!resp.ok) {
        const body = await resp.text()
        return `Error: Prometheus returned HTTP ${resp.status}.\n${body}`
      }

      const data = await resp.json()
      if (data.status === "error") {
        return `PromQL Error: ${data.errorType} — ${data.error}`
      }

      const header = [
        `Query: ${args.query}`,
        `Endpoint: ${endpoint}`,
        "\u2500".repeat(60),
        "",
      ].join("\n")

      return header + formatPromResult(data)
    } catch (e: any) {
      if (e.name === "TimeoutError" || e.name === "AbortError") {
        return `Error: Query timed out after 30s. Try a simpler query or increase timeout.`
      }
      return `Error: Could not reach Prometheus at ${endpoint}.\n${e.message}`
    }
  },
})

export const query_metrics_range = tool({
  description:
    "Execute a PromQL range query against Prometheus. Returns time-series " +
    "data over a time window. Use for trend analysis like CPU over the " +
    "last hour or error rate over the last day.",
  args: {
    query: tool.schema
      .string()
      .describe("PromQL query expression"),
    endpoint: tool.schema
      .string()
      .optional()
      .describe("Prometheus endpoint URL (auto-detected if not specified)"),
    start: tool.schema
      .string()
      .describe("Start time as relative duration (e.g. '1h', '30m', '1d') or RFC3339 timestamp"),
    end: tool.schema
      .string()
      .optional()
      .describe("End time as relative duration or RFC3339 (default: now)"),
    step: tool.schema
      .string()
      .optional()
      .describe("Query resolution step (e.g. '60s', '5m', default: '60s')"),
  },
  async execute(args, context) {
    let endpoint = args.endpoint
    if (!endpoint) {
      const discovered = await findPrometheusEndpoint(context)
      if (!discovered) {
        return "Error: No Prometheus endpoint found. Set PROMETHEUS_URL or pass endpoint parameter."
      }
      endpoint = discovered.url
    }

    const now = Date.now()
    const step = args.step || "60s"

    // Parse start time — relative duration or absolute
    let startTime: string
    const startMs = parseDuration(args.start)
    if (startMs > 0) {
      startTime = new Date(now - startMs).toISOString()
    } else {
      startTime = args.start // assume RFC3339
    }

    // Parse end time
    let endTime: string
    if (args.end) {
      const endMs = parseDuration(args.end)
      if (endMs > 0) {
        endTime = new Date(now - endMs).toISOString()
      } else {
        endTime = args.end
      }
    } else {
      endTime = new Date(now).toISOString()
    }

    const params = new URLSearchParams({
      query: args.query,
      start: startTime,
      end: endTime,
      step: step,
    })

    const url = `${endpoint}/api/v1/query_range?${params.toString()}`

    try {
      const resp = await fetch(url, { signal: AbortSignal.timeout(30000) })
      if (!resp.ok) {
        const body = await resp.text()
        return `Error: Prometheus returned HTTP ${resp.status}.\n${body}`
      }

      const data = await resp.json()
      if (data.status === "error") {
        return `PromQL Error: ${data.errorType} — ${data.error}`
      }

      const header = [
        `Range Query: ${args.query}`,
        `Endpoint: ${endpoint}`,
        `Window: ${startTime} → ${endTime} (step: ${step})`,
        "\u2500".repeat(60),
        "",
      ].join("\n")

      return header + formatPromResult(data)
    } catch (e: any) {
      if (e.name === "TimeoutError" || e.name === "AbortError") {
        return `Error: Range query timed out after 30s. Try a shorter time range or larger step.`
      }
      return `Error: Could not reach Prometheus at ${endpoint}.\n${e.message}`
    }
  },
})

export const check_targets = tool({
  description:
    "Check Prometheus scrape target health. Shows active and dropped " +
    "targets grouped by job with health status, last scrape time, " +
    "and last error. Useful for verifying monitoring coverage.",
  args: {
    endpoint: tool.schema
      .string()
      .optional()
      .describe("Prometheus endpoint URL (auto-detected if not specified)"),
  },
  async execute(args, context) {
    let endpoint = args.endpoint
    if (!endpoint) {
      const discovered = await findPrometheusEndpoint(context)
      if (!discovered) {
        return "Error: No Prometheus endpoint found. Set PROMETHEUS_URL or pass endpoint parameter."
      }
      endpoint = discovered.url
    }

    const url = `${endpoint}/api/v1/targets`

    try {
      const resp = await fetch(url, { signal: AbortSignal.timeout(15000) })
      if (!resp.ok) {
        const body = await resp.text()
        return `Error: Prometheus returned HTTP ${resp.status}.\n${body}`
      }

      const data = await resp.json()
      if (data.status === "error") {
        return `Error: ${data.errorType} — ${data.error}`
      }

      const active = data.data?.activeTargets || []
      const dropped = data.data?.droppedTargets || []

      const lines: string[] = [
        "Prometheus Targets",
        "==================",
        `Endpoint: ${endpoint}`,
        `Active: ${active.length} | Dropped: ${dropped.length}`,
        "\u2500".repeat(60),
        "",
      ]

      // Group active targets by job
      const byJob: Record<string, any[]> = {}
      for (const t of active) {
        const job = t.labels?.job || "unknown"
        if (!byJob[job]) byJob[job] = []
        byJob[job].push(t)
      }

      for (const [job, targets] of Object.entries(byJob)) {
        const healthy = targets.filter((t: any) => t.health === "up").length
        lines.push(`Job: ${job} (${healthy}/${targets.length} healthy)`)
        for (const t of targets) {
          const health = t.health === "up" ? "UP" : "DOWN"
          const scrapeUrl = t.scrapeUrl || t.labels?.instance || "?"
          const lastScrape = t.lastScrape
            ? new Date(t.lastScrape).toISOString()
            : "never"
          const lastError = t.lastError || ""
          lines.push(`  [${health}] ${scrapeUrl}`)
          lines.push(`    Last scrape: ${lastScrape}`)
          if (lastError) {
            lines.push(`    Last error:  ${lastError}`)
          }
        }
        lines.push("")
      }

      if (dropped.length > 0) {
        lines.push(`\u2500\u2500 Dropped Targets (${dropped.length}) \u2500\u2500`)
        for (const t of dropped.slice(0, 10)) {
          const labels = Object.entries(t.discoveredLabels || {})
            .map(([k, v]) => `${k}="${v}"`)
            .join(", ")
          lines.push(`  {${labels}}`)
        }
        if (dropped.length > 10) {
          lines.push(`  ... and ${dropped.length - 10} more`)
        }
      }

      return lines.join("\n")
    } catch (e: any) {
      if (e.name === "TimeoutError" || e.name === "AbortError") {
        return `Error: Targets request timed out after 15s.`
      }
      return `Error: Could not reach Prometheus at ${endpoint}.\n${e.message}`
    }
  },
})
