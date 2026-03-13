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
    "Analyze a project's codebase to gather information needed for README generation. " +
    "Examines package manifests, entry points, build scripts, directory structure, " +
    "and git history. Returns a structured project summary.",
  args: {
    path: tool.schema
      .string()
      .optional()
      .describe("Project root path (defaults to current directory)"),
  },
  async execute(args, context) {
    const root = args.path || context.directory || "."
    const sections: string[] = []

    sections.push("# Project Analysis")
    sections.push("")

    // 1. Directory structure (top level)
    const tree = await run(["find", root, "-maxdepth", "2", "-not", "-path", "*/.*", "-not", "-path", "*/node_modules/*", "-not", "-path", "*/vendor/*", "-not", "-path", "*/__pycache__/*", "-not", "-path", "*/target/*", "-not", "-path", "*/dist/*"])
    if (tree.ok) {
      sections.push("## Directory Structure (top 2 levels)")
      sections.push("```")
      sections.push(tree.out)
      sections.push("```")
      sections.push("")
    }

    // 2. Detect language and package manager
    const manifests = [
      { file: "package.json", lang: "JavaScript/TypeScript", pm: "npm/bun/pnpm" },
      { file: "go.mod", lang: "Go", pm: "go modules" },
      { file: "Cargo.toml", lang: "Rust", pm: "cargo" },
      { file: "pyproject.toml", lang: "Python", pm: "pip/poetry/uv" },
      { file: "requirements.txt", lang: "Python", pm: "pip" },
      { file: "Gemfile", lang: "Ruby", pm: "bundler" },
      { file: "pom.xml", lang: "Java", pm: "maven" },
      { file: "build.gradle", lang: "Java/Kotlin", pm: "gradle" },
      { file: "mix.exs", lang: "Elixir", pm: "mix" },
      { file: "composer.json", lang: "PHP", pm: "composer" },
    ]

    const detected: string[] = []
    for (const m of manifests) {
      const check = await run(["find", root, "-maxdepth", "1", "-name", m.file])
      if (check.ok && check.out.length > 0) {
        detected.push(`${m.lang} (${m.pm})`)

        // Read manifest content
        const content = await run(["cat", `${root}/${m.file}`])
        if (content.ok) {
          sections.push(`## ${m.file}`)
          sections.push("```")
          // Truncate long manifests
          const lines = content.out.split("\n")
          sections.push(lines.slice(0, 80).join("\n"))
          if (lines.length > 80) sections.push(`... (${lines.length - 80} more lines)`)
          sections.push("```")
          sections.push("")
        }
      }
    }

    if (detected.length > 0) {
      sections.splice(2, 0, `## Detected Stack`, detected.join(", "), "")
    } else {
      sections.splice(2, 0, `## Detected Stack`, "Unable to detect (no recognized manifest files)", "")
    }

    // 3. Build/run scripts
    const buildFiles = ["Makefile", "Dockerfile", "docker-compose.yml", "docker-compose.yaml", "Justfile", "Taskfile.yml"]
    const foundBuild: string[] = []
    for (const bf of buildFiles) {
      const check = await run(["find", root, "-maxdepth", "1", "-name", bf])
      if (check.ok && check.out.length > 0) {
        foundBuild.push(bf)
      }
    }
    if (foundBuild.length > 0) {
      sections.push("## Build/Run Files")
      sections.push(foundBuild.join(", "))
      sections.push("")
    }

    // 4. CI configuration
    const ciPaths = [".github/workflows", ".gitlab-ci.yml", ".circleci", "Jenkinsfile", ".travis.yml"]
    const foundCI: string[] = []
    for (const ci of ciPaths) {
      const check = await run(["find", root, "-maxdepth", "2", "-path", `*/${ci}*`, "-not", "-path", "*/node_modules/*"])
      if (check.ok && check.out.length > 0) {
        foundCI.push(ci)
      }
    }
    if (foundCI.length > 0) {
      sections.push("## CI/CD")
      sections.push(foundCI.join(", "))
      sections.push("")
    }

    // 5. Existing README
    const readme = await run(["cat", `${root}/README.md`])
    if (readme.ok && readme.out.length > 0) {
      sections.push("## Existing README.md")
      sections.push("```markdown")
      const lines = readme.out.split("\n")
      sections.push(lines.slice(0, 100).join("\n"))
      if (lines.length > 100) sections.push(`... (${lines.length - 100} more lines)`)
      sections.push("```")
      sections.push("")
    } else {
      sections.push("## Existing README.md")
      sections.push("No README.md found.")
      sections.push("")
    }

    // 6. Recent git history
    const log = await run(["git", "log", "--oneline", "-15"])
    if (log.ok && log.out.length > 0) {
      sections.push("## Recent Git History (last 15 commits)")
      sections.push("```")
      sections.push(log.out)
      sections.push("```")
      sections.push("")
    }

    // 7. Git remote
    const remote = await run(["git", "remote", "-v"])
    if (remote.ok && remote.out.length > 0) {
      sections.push("## Git Remote")
      sections.push("```")
      sections.push(remote.out)
      sections.push("```")
      sections.push("")
    }

    // 8. License
    const licenseFiles = ["LICENSE", "LICENSE.md", "LICENSE.txt", "LICENCE"]
    for (const lf of licenseFiles) {
      const check = await run(["head", "-5", `${root}/${lf}`])
      if (check.ok && check.out.length > 0) {
        sections.push("## License File")
        sections.push(`Found: ${lf}`)
        sections.push(check.out.split("\n")[0])
        sections.push("")
        break
      }
    }

    return sections.join("\n")
  },
})
