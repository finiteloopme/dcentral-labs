import { tool } from "@opencode-ai/plugin"

async function run(cmd: string[]): Promise<{ ok: boolean; out: string }> {
  try {
    const result = await Bun.$`${cmd}`.text()
    return { ok: true, out: result.trim() }
  } catch (e: any) {
    return { ok: false, out: e?.stderr?.toString?.()?.trim() || e.message || "" }
  }
}

export default tool({
  description:
    "Validate an existing README.md against the actual project state. " +
    "Checks for stale instructions, missing prerequisites, referenced files " +
    "that don't exist, broken commands, and structural issues. " +
    "Returns a list of issues found, categorized by severity.",
  args: {
    path: tool.schema
      .string()
      .optional()
      .describe("Path to the README.md file (defaults to ./README.md)"),
  },
  async execute(args, context) {
    const readmePath = args.path || `${context.directory || "."}/README.md`
    const root = readmePath.replace(/\/README\.md$/, "") || "."

    // Read the README
    const readme = await run(["cat", readmePath])
    if (!readme.ok || readme.out.length === 0) {
      return `No README.md found at ${readmePath}.`
    }

    const content = readme.out
    const lines = content.split("\n")
    const issues: { severity: string; message: string }[] = []

    // 1. Check required sections
    const requiredHeadings = ["prerequisites", "quickstart", "quick start", "getting started", "install", "installation", "setup"]
    const headings = lines
      .filter((l) => l.startsWith("#"))
      .map((l) => l.replace(/^#+\s*/, "").toLowerCase())

    const hasPrereq = requiredHeadings.some((r) =>
      headings.some((h) => h.includes(r.split(" ")[0]))
    )
    if (!hasPrereq) {
      issues.push({
        severity: "warning",
        message: "Missing a Prerequisites / Install section",
      })
    }

    const quickstartKeywords = ["quickstart", "quick start", "getting started", "usage", "install"]
    const hasQuickstart = quickstartKeywords.some((q) =>
      headings.some((h) => h.includes(q))
    )
    if (!hasQuickstart) {
      issues.push({
        severity: "warning",
        message: "Missing a Quickstart / Getting Started / Usage section",
      })
    }

    // 2. Check for title
    if (!lines[0]?.startsWith("# ")) {
      issues.push({
        severity: "error",
        message: "README should start with a # Title",
      })
    }

    // 3. Check for one-liner description
    const firstNonEmpty = lines.slice(1).find((l) => l.trim().length > 0)
    if (!firstNonEmpty || firstNonEmpty.startsWith("#")) {
      issues.push({
        severity: "warning",
        message: "Missing one-liner project description after title",
      })
    }

    // 4. Check for TODO/FIXME/HACK comments (these should be issues)
    const todoPattern = /\b(TODO|FIXME|HACK|XXX|TEMP)\b/i
    for (let i = 0; i < lines.length; i++) {
      if (todoPattern.test(lines[i])) {
        issues.push({
          severity: "warning",
          message: `Line ${i + 1}: Contains "${lines[i].match(todoPattern)?.[0]}" -- should be a GitHub issue instead`,
        })
      }
    }

    // 5. Check for referenced files that don't exist
    const fileRefPattern = /`([^`]+\.[a-z]{1,5})`/g
    const checked = new Set<string>()
    for (const line of lines) {
      let match
      while ((match = fileRefPattern.exec(line)) !== null) {
        const ref = match[1]
        // Skip things that look like commands or URLs
        if (ref.includes(" ") || ref.includes("://") || ref.startsWith("*.")) continue
        if (checked.has(ref)) continue
        checked.add(ref)

        const exists = await run(["find", root, "-path", `*/${ref}`, "-maxdepth", "4"])
        if (!exists.ok || exists.out.length === 0) {
          // Only flag if it looks like a real file path
          if (ref.includes("/") || ref.match(/\.(md|ts|js|py|go|rs|json|yaml|yml|toml|sh)$/)) {
            issues.push({
              severity: "info",
              message: `Referenced file \`${ref}\` may not exist in the project`,
            })
          }
        }
      }
    }

    // 6. Check for excessive length
    if (lines.length > 200) {
      issues.push({
        severity: "warning",
        message: `README is ${lines.length} lines long -- consider trimming to keep it scannable`,
      })
    }

    // 7. Check for empty sections
    for (let i = 0; i < lines.length; i++) {
      if (lines[i].startsWith("#")) {
        const nextHeading = lines.slice(i + 1).findIndex((l) => l.startsWith("#"))
        const sectionEnd = nextHeading === -1 ? lines.length : i + 1 + nextHeading
        const sectionContent = lines
          .slice(i + 1, sectionEnd)
          .filter((l) => l.trim().length > 0)
        if (sectionContent.length === 0) {
          issues.push({
            severity: "warning",
            message: `Empty section: "${lines[i].replace(/^#+\s*/, "")}" -- remove it or add content`,
          })
        }
      }
    }

    // 8. Check if package.json scripts are referenced correctly
    const pkgJson = await run(["cat", `${root}/package.json`])
    if (pkgJson.ok) {
      try {
        const pkg = JSON.parse(pkgJson.out)
        const scripts = Object.keys(pkg.scripts || {})
        // Check if README mentions npm/yarn/bun run commands that don't match scripts
        const runPattern = /(?:npm|yarn|bun|pnpm)\s+(?:run\s+)?(\w[\w-]*)/g
        for (const line of lines) {
          let m
          while ((m = runPattern.exec(line)) !== null) {
            const scriptName = m[1]
            // Skip common commands that aren't scripts
            if (["install", "init", "create", "add", "remove", "update", "test", "start", "build"].includes(scriptName)) continue
            if (!scripts.includes(scriptName)) {
              issues.push({
                severity: "warning",
                message: `Referenced script "${scriptName}" not found in package.json scripts`,
              })
            }
          }
        }
      } catch {
        // Not valid JSON, skip
      }
    }

    // Format results
    if (issues.length === 0) {
      return "README.md validation passed. No issues found."
    }

    const errors = issues.filter((i) => i.severity === "error")
    const warnings = issues.filter((i) => i.severity === "warning")
    const infos = issues.filter((i) => i.severity === "info")

    const result: string[] = [
      `README.md Validation: ${issues.length} issue(s) found`,
      "",
    ]

    if (errors.length > 0) {
      result.push(`Errors (${errors.length}):`)
      for (const e of errors) result.push(`  x ${e.message}`)
      result.push("")
    }
    if (warnings.length > 0) {
      result.push(`Warnings (${warnings.length}):`)
      for (const w of warnings) result.push(`  ! ${w.message}`)
      result.push("")
    }
    if (infos.length > 0) {
      result.push(`Info (${infos.length}):`)
      for (const i of infos) result.push(`  i ${i.message}`)
      result.push("")
    }

    return result.join("\n")
  },
})
