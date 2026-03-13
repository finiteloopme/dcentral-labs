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
    "Generate a minimalist README.md scaffold based on the project analysis. " +
    "Detects the project type, language, dependencies, and entry points, " +
    "then produces a clean README with title, one-liner, prerequisites, " +
    "quickstart, and license. The output is ready to write to README.md.",
  args: {
    name: tool.schema
      .string()
      .optional()
      .describe("Project name (auto-detected from manifest or directory if omitted)"),
    description: tool.schema
      .string()
      .optional()
      .describe("One-liner project description (auto-detected if omitted)"),
  },
  async execute(args, context) {
    const root = context.directory || "."

    // Detect project name
    let projectName = args.name || ""
    let projectDesc = args.description || ""
    let lang = ""
    let installCmd = ""
    let runCmd = ""
    let prerequisites: string[] = []

    // Try package.json
    const pkgJson = await run(["cat", `${root}/package.json`])
    if (pkgJson.ok) {
      try {
        const pkg = JSON.parse(pkgJson.out)
        if (!projectName) projectName = pkg.name || ""
        if (!projectDesc) projectDesc = pkg.description || ""
        lang = "JavaScript/TypeScript"

        // Detect package manager
        const hasBunLock = await run(["find", root, "-maxdepth", "1", "-name", "bun.lockb"])
        const hasPnpmLock = await run(["find", root, "-maxdepth", "1", "-name", "pnpm-lock.yaml"])
        const hasYarnLock = await run(["find", root, "-maxdepth", "1", "-name", "yarn.lock"])

        let pm = "npm"
        if (hasBunLock.ok && hasBunLock.out) pm = "bun"
        else if (hasPnpmLock.ok && hasPnpmLock.out) pm = "pnpm"
        else if (hasYarnLock.ok && hasYarnLock.out) pm = "yarn"

        installCmd = `${pm} install`
        if (pkg.scripts?.dev) runCmd = `${pm} run dev`
        else if (pkg.scripts?.start) runCmd = `${pm} ${pm === "npm" ? "run " : ""}start`
        else if (pkg.scripts?.build) runCmd = `${pm} run build`

        // Node version
        const engines = pkg.engines?.node
        if (engines) {
          prerequisites.push(`[Node.js](https://nodejs.org) ${engines}`)
        } else {
          prerequisites.push("[Node.js](https://nodejs.org) >= 18")
        }
        if (pm === "bun") prerequisites.push("[Bun](https://bun.sh)")
        if (pm === "pnpm") prerequisites.push("[pnpm](https://pnpm.io)")
      } catch {
        // Invalid JSON
      }
    }

    // Try go.mod
    const goMod = await run(["cat", `${root}/go.mod`])
    if (goMod.ok && !lang) {
      lang = "Go"
      const moduleMatch = goMod.out.match(/^module\s+(.+)$/m)
      if (moduleMatch && !projectName) {
        projectName = moduleMatch[1].split("/").pop() || ""
      }
      const goVerMatch = goMod.out.match(/^go\s+(.+)$/m)
      prerequisites.push(`[Go](https://go.dev) ${goVerMatch ? `>= ${goVerMatch[1]}` : ""}`)
      installCmd = "go mod download"
      runCmd = "go run ."
    }

    // Try Cargo.toml
    const cargoToml = await run(["cat", `${root}/Cargo.toml`])
    if (cargoToml.ok && !lang) {
      lang = "Rust"
      const nameMatch = cargoToml.out.match(/^name\s*=\s*"(.+)"/m)
      const descMatch = cargoToml.out.match(/^description\s*=\s*"(.+)"/m)
      if (nameMatch && !projectName) projectName = nameMatch[1]
      if (descMatch && !projectDesc) projectDesc = descMatch[1]
      prerequisites.push("[Rust](https://rustup.rs)")
      installCmd = "cargo build"
      runCmd = "cargo run"
    }

    // Try pyproject.toml / requirements.txt
    const pyProject = await run(["cat", `${root}/pyproject.toml`])
    const requirements = await run(["cat", `${root}/requirements.txt`])
    if ((pyProject.ok || requirements.ok) && !lang) {
      lang = "Python"
      if (pyProject.ok) {
        const nameMatch = pyProject.out.match(/^name\s*=\s*"(.+)"/m)
        const descMatch = pyProject.out.match(/^description\s*=\s*"(.+)"/m)
        if (nameMatch && !projectName) projectName = nameMatch[1]
        if (descMatch && !projectDesc) projectDesc = descMatch[1]
      }
      prerequisites.push("[Python](https://python.org) >= 3.10")
      installCmd = "pip install -r requirements.txt"
      runCmd = "python main.py"
    }

    // Fallback: directory name
    if (!projectName) {
      const dirName = await run(["basename", root])
      projectName = dirName.ok ? dirName.out : "project"
    }

    // Detect license
    let license = ""
    for (const lf of ["LICENSE", "LICENSE.md", "LICENSE.txt"]) {
      const lic = await run(["head", "-3", `${root}/${lf}`])
      if (lic.ok && lic.out) {
        if (lic.out.includes("MIT")) license = "MIT"
        else if (lic.out.includes("Apache")) license = "Apache 2.0"
        else if (lic.out.includes("GPL")) license = "GPL"
        else if (lic.out.includes("BSD")) license = "BSD"
        else license = lf
        break
      }
    }

    // Detect Makefile targets
    let makeTargets = ""
    const makefile = await run(["cat", `${root}/Makefile`])
    if (makefile.ok) {
      const targets = makefile.out
        .split("\n")
        .filter((l) => /^[a-zA-Z_-]+:/.test(l))
        .map((l) => l.split(":")[0])
        .filter((t) => !t.startsWith(".") && !t.startsWith("_"))
        .slice(0, 8)
      if (targets.length > 0) {
        makeTargets = targets.join(", ")
      }
    }

    // Build the README
    const sections: string[] = []

    // Title + description
    sections.push(`# ${projectName}`)
    sections.push("")
    if (projectDesc) {
      sections.push(projectDesc)
      sections.push("")
    }

    // Prerequisites
    if (prerequisites.length > 0) {
      sections.push("## Prerequisites")
      sections.push("")
      for (const p of prerequisites) sections.push(`- ${p}`)
      sections.push("")
    }

    // Quickstart
    sections.push("## Quickstart")
    sections.push("")
    sections.push("```bash")

    // Clone step (detect remote)
    const remote = await run(["git", "remote", "get-url", "origin"])
    if (remote.ok && remote.out) {
      sections.push(`git clone ${remote.out}`)
      sections.push(`cd ${projectName}`)
    }

    if (installCmd) sections.push(installCmd)
    if (runCmd) sections.push(runCmd)

    // If we have nothing, provide a placeholder
    if (!installCmd && !runCmd) {
      sections.push("# TODO: add install and run commands")
    }

    sections.push("```")
    sections.push("")

    // Makefile targets (if any)
    if (makeTargets) {
      sections.push("## Available Commands")
      sections.push("")
      sections.push(`\`make [${makeTargets}]\``)
      sections.push("")
    }

    // License
    if (license) {
      sections.push("## License")
      sections.push("")
      sections.push(license)
      sections.push("")
    }

    return sections.join("\n")
  },
})
