import { tool } from "@opencode-ai/plugin"

// Module-level cache for environment check results
let cachedEnv: string | null = null

async function run(cmd: string[]): Promise<{ ok: boolean; out: string }> {
  try {
    const result = await Bun.$`${cmd}`.text()
    return { ok: true, out: result.trim() }
  } catch (e: any) {
    return { ok: false, out: e?.stderr?.toString?.()?.trim() || e.message || "unknown error" }
  }
}

async function runChecks(): Promise<string> {
  const lines: string[] = []
  const warnings: string[] = []
  let gitOk = false
  let ghOk = false
  let repoOk = false
  let isGitHub = false

  lines.push("Git/GitHub Operations - Environment Check")
  lines.push("==========================================")

  // 1. git installed
  const gitVer = await run(["git", "--version"])
  if (gitVer.ok) {
    lines.push(`  git installed          : ${gitVer.out.replace("git version ", "")}`)
    gitOk = true
  } else {
    lines.push("  git installed          : NOT FOUND")
    lines.push("")
    lines.push("FATAL: git is required. Install it from https://git-scm.com")
    return lines.join("\n")
  }

  // 2. Inside a git repo
  const inRepo = await run(["git", "rev-parse", "--is-inside-work-tree"])
  if (inRepo.ok && inRepo.out === "true") {
    lines.push("  Inside git repo        : yes")
    repoOk = true
  } else {
    lines.push("  Inside git repo        : NO")
    lines.push("")
    lines.push("FATAL: Not inside a git repository. Run `git init` or navigate to a repo.")
    return lines.join("\n")
  }

  // 3. Remote configured
  const remotes = await run(["git", "remote", "-v"])
  if (remotes.ok && remotes.out.length > 0) {
    const firstLine = remotes.out.split("\n")[0]
    const remoteUrl = firstLine.split(/\s+/)[1] || "unknown"
    lines.push(`  Remote                 : ${remoteUrl}`)

    // 4. Is it GitHub?
    if (remoteUrl.includes("github.com")) {
      lines.push("  GitHub remote          : yes")
      isGitHub = true
    } else {
      lines.push("  GitHub remote          : no (non-GitHub remote detected)")
      warnings.push("Remote is not GitHub. GitHub operations (issues, PRs, releases) may not work.")
    }
  } else {
    lines.push("  Remote                 : none configured")
    warnings.push("No remote configured. GitHub operations require a remote. Run `git remote add origin <url>`.")
  }

  // 5. gh CLI installed
  const ghVer = await run(["gh", "--version"])
  if (ghVer.ok) {
    const ver = ghVer.out.split("\n")[0].replace("gh version ", "").split(" ")[0]
    lines.push(`  gh CLI installed       : ${ver}`)
    ghOk = true
  } else {
    lines.push("  gh CLI installed       : NOT FOUND")
    warnings.push("gh CLI is required for GitHub operations (issues, PRs, releases, reviews). Install: https://cli.github.com")
  }

  // 6. gh authenticated
  if (ghOk) {
    const ghAuth = await run(["gh", "auth", "status"])
    // gh auth status outputs to stderr on success, but exits 0
    if (ghAuth.ok) {
      // Extract username from output
      const authOut = ghAuth.out
      const userMatch = authOut.match(/Logged in to .* account (\S+)/) ||
                        authOut.match(/Logged in to .* as (\S+)/)
      const user = userMatch ? userMatch[1] : "yes"
      lines.push(`  gh authenticated       : ${user}`)
    } else {
      lines.push("  gh authenticated       : NO")
      warnings.push("gh CLI is not authenticated. Run `gh auth login` to authenticate.")
    }
  } else {
    lines.push("  gh authenticated       : SKIPPED (gh not installed)")
  }

  // 7. Repo access via gh
  if (ghOk && isGitHub) {
    const repoView = await run(["gh", "repo", "view", "--json", "name,owner,defaultBranchRef"])
    if (repoView.ok) {
      try {
        const repo = JSON.parse(repoView.out)
        const owner = repo.owner?.login || "unknown"
        const name = repo.name || "unknown"
        const defaultBranch = repo.defaultBranchRef?.name || "unknown"
        lines.push(`  Repo access            : ${owner}/${name}`)
        lines.push(`  Default branch         : ${defaultBranch}`)
      } catch {
        lines.push("  Repo access            : yes (could not parse details)")
      }
    } else {
      lines.push("  Repo access            : NO")
      warnings.push("Cannot access this repo via gh. Check permissions or run `gh auth refresh`.")
    }

    // 8. Labels
    const labels = await run(["gh", "label", "list", "--limit", "20", "--json", "name"])
    if (labels.ok) {
      try {
        const parsed = JSON.parse(labels.out)
        if (parsed.length > 0) {
          const names = parsed.map((l: any) => l.name).join(", ")
          lines.push(`  Labels                 : ${names}`)
        } else {
          lines.push("  Labels                 : none")
          warnings.push("No labels found. Run /git-ops-init with setup to create defaults.")
        }
      } catch {
        lines.push("  Labels                 : unable to parse")
      }
    }

    // 9. Milestones
    const milestones = await run(["gh", "api", "repos/{owner}/{repo}/milestones", "--jq", ".[].title"])
    if (milestones.ok && milestones.out.length > 0) {
      lines.push(`  Milestones             : ${milestones.out.split("\n").join(", ")}`)
    } else {
      lines.push("  Milestones             : none")
    }

    // 10. GitHub Projects
    const projects = await run(["gh", "project", "list", "--limit", "5", "--format", "json"])
    if (projects.ok) {
      try {
        const parsed = JSON.parse(projects.out)
        if (parsed.projects && parsed.projects.length > 0) {
          const names = parsed.projects.map((p: any) => p.title).join(", ")
          lines.push(`  GitHub Projects        : ${names}`)
        } else {
          lines.push("  GitHub Projects        : none")
        }
      } catch {
        lines.push("  GitHub Projects        : none")
      }
    } else {
      lines.push("  GitHub Projects        : none")
    }
  }

  // Summary
  lines.push("")
  if (warnings.length > 0) {
    lines.push("Warnings:")
    for (const w of warnings) {
      lines.push(`  - ${w}`)
    }
    lines.push("")
  }

  if (gitOk && ghOk && isGitHub) {
    lines.push("Ready to use all git-ops tools.")
  } else if (gitOk && !ghOk) {
    lines.push("Git operations available. GitHub operations require `gh` CLI.")
    lines.push("Install: https://cli.github.com")
  } else if (gitOk && ghOk && !isGitHub) {
    lines.push("Git operations available. GitHub operations may not work (non-GitHub remote).")
  }

  return lines.join("\n")
}

/**
 * Shared helper for other tools to call. Runs checks on first call,
 * returns cached result on subsequent calls. Returns null if environment
 * is ready, or an error string if there's a hard failure.
 */
export async function ensureEnvironment(): Promise<string | null> {
  if (cachedEnv === null) {
    cachedEnv = await runChecks()
  }
  // Check for hard failures
  if (cachedEnv.includes("FATAL:")) {
    return cachedEnv
  }
  return null
}

/**
 * Get the full cached environment report.
 */
export async function getEnvironmentReport(): Promise<string> {
  if (cachedEnv === null) {
    cachedEnv = await runChecks()
  }
  return cachedEnv
}

/**
 * Clear the cache so the next call re-runs checks.
 */
export function clearCache(): void {
  cachedEnv = null
}

export default tool({
  description:
    "Check the git/GitHub environment and readiness for git-ops operations. " +
    "Validates git, gh CLI, authentication, remote configuration, labels, milestones, and projects. " +
    "Auto-runs on first use of any git-ops tool. Use force=true to re-check.",
  args: {
    force: tool.schema
      .boolean()
      .optional()
      .describe("Force re-check even if cached results exist"),
  },
  async execute(args) {
    if (args.force) {
      clearCache()
    }
    return await getEnvironmentReport()
  },
})

export const setup = tool({
  description:
    "Set up default labels and milestones for the repository. " +
    "Only run after user confirms they want to create these resources.",
  args: {
    labels: tool.schema
      .boolean()
      .optional()
      .describe("Create default labels (bug, feature, chore, priority:high/medium/low, status:in-progress/blocked)"),
    milestone_name: tool.schema
      .string()
      .optional()
      .describe("Create a milestone with this name (e.g., 'v1.0')"),
    milestone_due: tool.schema
      .string()
      .optional()
      .describe("Due date for the milestone in YYYY-MM-DD format"),
  },
  async execute(args) {
    const results: string[] = []

    if (args.labels) {
      const defaultLabels = [
        { name: "bug", description: "Something isn't working", color: "d73a4a" },
        { name: "feature", description: "New feature or request", color: "0e8a16" },
        { name: "chore", description: "Maintenance or technical debt", color: "fbca04" },
        { name: "priority:high", description: "High priority", color: "b60205" },
        { name: "priority:medium", description: "Medium priority", color: "e99695" },
        { name: "priority:low", description: "Low priority", color: "0075ca" },
        { name: "status:in-progress", description: "Currently being worked on", color: "5319e7" },
        { name: "status:blocked", description: "Blocked by something", color: "800000" },
      ]

      results.push("Creating labels:")
      for (const label of defaultLabels) {
        try {
          await Bun.$`gh label create ${label.name} --description ${label.description} --color ${label.color} --force`.text()
          results.push(`  + ${label.name}`)
        } catch (e: any) {
          results.push(`  x ${label.name} (failed: ${e.message})`)
        }
      }
    }

    if (args.milestone_name) {
      results.push("")
      results.push("Creating milestone:")
      try {
        const cmd = ["gh", "api", "repos/{owner}/{repo}/milestones", "-f", `title=${args.milestone_name}`]
        if (args.milestone_due) {
          cmd.push("-f", `due_on=${args.milestone_due}T00:00:00Z`)
        }
        await Bun.$`${cmd}`.text()
        results.push(`  + ${args.milestone_name}${args.milestone_due ? ` (due: ${args.milestone_due})` : ""}`)
      } catch (e: any) {
        results.push(`  x ${args.milestone_name} (failed: ${e.message})`)
      }
    }

    if (results.length === 0) {
      return "No setup actions requested. Pass labels=true and/or milestone_name to create resources."
    }

    // Clear the cache so the next init check picks up new resources
    clearCache()

    return results.join("\n")
  },
})
