import { tool } from "@opencode-ai/plugin"
import { existsSync } from "fs"
import { randomBytes } from "crypto"

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

async function getDefaultBranch(): Promise<string> {
  const result = await run([
    "gh",
    "repo",
    "view",
    "--json",
    "defaultBranchRef",
    "--jq",
    ".defaultBranchRef.name",
  ])
  return result.ok ? result.out : "main"
}

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 40)
}

function generateHash(): string {
  return randomBytes(4).toString("hex")
}

// ─── Individual Check Helpers (private) ──────────────────────────────

type PreflightCheck = "issue" | "clean" | "branch" | "plan"

const ALL_CHECKS: PreflightCheck[] = ["issue", "clean", "branch", "plan"]

async function checkIssue(issueNumber: number): Promise<{ lines: string[]; pass: boolean; title: string }> {
  const lines: string[] = []

  if (issueNumber <= 0) {
    lines.push("   FAIL: Issue number must be a positive integer.")
    return { lines, pass: false, title: "" }
  }

  const result = await run([
    "gh", "issue", "view", String(issueNumber),
    "--json", "number,title,state,labels,url",
  ])

  if (!result.ok) {
    lines.push(`   FAIL: Could not find issue #${issueNumber}.`)
    lines.push(`   Error: ${result.out}`)
    return { lines, pass: false, title: "" }
  }

  try {
    const issue = JSON.parse(result.out)
    const labels = issue.labels?.map((l: any) => l.name).join(", ") || "none"
    lines.push(`   PASS: Issue #${issue.number} -- ${issue.title}`)
    lines.push(`   State: ${issue.state}  |  Labels: ${labels}`)
    if (issue.state === "CLOSED") {
      lines.push("   WARNING: Issue is closed. Consider reopening or creating a new one.")
    }
    return { lines, pass: true, title: issue.title || "" }
  } catch {
    lines.push(`   PASS: Issue #${issueNumber} exists (could not parse details)`)
    return { lines, pass: true, title: "" }
  }
}

async function checkClean(workspace?: string): Promise<{ lines: string[]; pass: boolean }> {
  const lines: string[] = []

  // If workspace is provided, check the workspace's cleanliness
  // A freshly cloned workspace is always clean, but subsequent changes may dirty it
  const result = workspace
    ? await runInDir(["git", "status", "--porcelain"], workspace)
    : await run(["git", "status", "--porcelain"])

  if (!result.ok) {
    lines.push(`   FAIL: Could not check git status. Error: ${result.out}`)
    return { lines, pass: false }
  }

  if (result.out === "") {
    lines.push("   PASS: Working tree is clean.")
    return { lines, pass: true }
  }

  const fileLines = result.out.split("\n")
  const staged = fileLines.filter(
    (l) => l.startsWith("M ") || l.startsWith("A ") || l.startsWith("D "),
  )
  const unstaged = fileLines.filter(
    (l) => l.startsWith(" M") || l.startsWith(" D") || l.startsWith("MM"),
  )
  const untracked = fileLines.filter((l) => l.startsWith("??"))

  lines.push(`   FAIL: Working tree is dirty. ${fileLines.length} file(s) with changes.`)
  if (staged.length > 0) {
    lines.push(`   Staged (${staged.length}):`)
    for (const f of staged) lines.push(`     ${f}`)
  }
  if (unstaged.length > 0) {
    lines.push(`   Unstaged (${unstaged.length}):`)
    for (const f of unstaged) lines.push(`     ${f}`)
  }
  if (untracked.length > 0) {
    lines.push(`   Untracked (${untracked.length}):`)
    for (const f of untracked) lines.push(`     ${f}`)
  }
  lines.push("   Stash or commit changes before proceeding.")
  return { lines, pass: false }
}

async function checkBranch(
  issueNumber: number,
  issueTitle: string,
  type: string,
  sourceDir: string,
): Promise<{ lines: string[]; pass: boolean; branchName: string; workspacePath: string }> {
  const lines: string[] = []
  const slug = slugify(issueTitle)
  const branchName = `${type}/${issueNumber}-${slug}`

  // Get remote URL from the source repo
  const remoteResult = await run(["git", "-C", sourceDir, "remote", "get-url", "origin"])
  if (!remoteResult.ok) {
    lines.push(`   FAIL: Could not get remote URL. ${remoteResult.out}`)
    return { lines, pass: false, branchName, workspacePath: "" }
  }
  const remoteUrl = remoteResult.out

  const defaultBranch = await getDefaultBranch()
  const hash = generateHash()
  const wsName = `issue-${issueNumber}-${slug}`.slice(0, 50)
  const wsPath = `/tmp/agent-${wsName}-${hash}`

  // Clone with --dissociate --reference for speed + full isolation
  lines.push(`   Creating isolated workspace: ${wsPath}`)
  const cloneResult = await run([
    "git", "clone",
    "--dissociate", "--reference", sourceDir,
    "--single-branch", "--branch", defaultBranch,
    remoteUrl, wsPath,
  ])

  if (!cloneResult.ok) {
    // Fallback: try without --reference
    const fallbackResult = await run([
      "git", "clone",
      "--single-branch", "--branch", defaultBranch,
      remoteUrl, wsPath,
    ])
    if (!fallbackResult.ok) {
      lines.push(`   FAIL: Could not clone repository.`)
      lines.push(`   Error: ${fallbackResult.out}`)
      return { lines, pass: false, branchName, workspacePath: "" }
    }
    lines.push("   Clone method: direct (fallback)")
  } else {
    lines.push("   Clone method: dissociate + reference (fast)")
  }

  // Check if the branch already exists on the remote
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
      // Maybe created by fetch; try simple checkout
      const simpleCheckout = await runInDir(
        ["git", "checkout", branchName],
        wsPath,
      )
      if (!simpleCheckout.ok) {
        lines.push(`   FAIL: Could not switch to existing branch '${branchName}'.`)
        return { lines, pass: false, branchName, workspacePath: wsPath }
      }
    }
    lines.push(`   PASS: Checked out existing branch '${branchName}' in workspace`)
  } else {
    // Branch does not exist — create it from default branch
    const createResult = await runInDir(
      ["git", "checkout", "-b", branchName],
      wsPath,
    )
    if (!createResult.ok) {
      lines.push(`   FAIL: Could not create branch '${branchName}'.`)
      lines.push(`   Error: ${createResult.out}`)
      return { lines, pass: false, branchName, workspacePath: wsPath }
    }
    lines.push(`   PASS: Created branch '${branchName}' from '${defaultBranch}' in workspace`)
  }

  return { lines, pass: true, branchName, workspacePath: wsPath }
}

async function checkPlan(issueNumber: number): Promise<{ lines: string[]; pass: boolean }> {
  const lines: string[] = []

  if (issueNumber <= 0) {
    lines.push("   FAIL: Issue number must be a positive integer.")
    return { lines, pass: false }
  }

  const result = await run([
    "gh", "issue", "view", String(issueNumber),
    "--json", "comments",
  ])

  if (!result.ok) {
    lines.push(`   FAIL: Could not fetch comments for issue #${issueNumber}. Error: ${result.out}`)
    return { lines, pass: false }
  }

  try {
    const data = JSON.parse(result.out)
    const comments: Array<{ body: string; author: { login: string }; createdAt: string }> =
      data.comments || []

    for (const comment of comments) {
      if (comment.body.includes("## Implementation Plan")) {
        const date = comment.createdAt
          ? new Date(comment.createdAt).toISOString().slice(0, 10)
          : "unknown"
        lines.push(`   PASS: Implementation plan found on issue #${issueNumber}`)
        lines.push(`   Author: ${comment.author?.login || "unknown"}  |  Date: ${date}`)
        return { lines, pass: true }
      }
    }

    lines.push(`   WARN: No implementation plan found on issue #${issueNumber}`)
    lines.push("   Post a plan comment with '## Implementation Plan' header before starting work,")
    lines.push("   or confirm to proceed without one.")
    return { lines, pass: true } // WARN is not a failure
  } catch {
    lines.push(`   FAIL: Could not parse comments for issue #${issueNumber}. Raw: ${result.out}`)
    return { lines, pass: false }
  }
}

// ─── Tool Exports ────────────────────────────────────────────────────

export const preflight = tool({
  description:
    "Run pre-flight checks for issue-driven development. Checks: issue exists, " +
    "working tree is clean, isolated workspace with dedicated branch is created, " +
    "and implementation plan posted on the issue. The branch check now creates " +
    "a fully isolated clone in /tmp/agent-* instead of switching branches in the " +
    "main working tree. Returns the workspace path for subsequent operations. " +
    "Use the 'checks' parameter to run specific checks, or omit it to run all " +
    "checks in sequence.",
  args: {
    issue_number: tool.schema.number().describe("GitHub issue number"),
    checks: tool.schema
      .array(tool.schema.enum(["issue", "clean", "branch", "plan"]))
      .optional()
      .describe(
        "Which checks to run. Options: issue, clean, branch, plan. " +
        "Omit to run all checks in sequence.",
      ),
    type: tool.schema
      .enum(["feature", "fix", "chore", "docs", "refactor", "test"])
      .optional()
      .describe("Branch type prefix (default: feature)"),
    skip_plan_check: tool.schema
      .boolean()
      .optional()
      .describe(
        "Skip the implementation plan check (default: false). " +
        "Set to true for trivial issues where a plan is not needed.",
      ),
  },
  async execute(args, context) {
    const checksToRun: PreflightCheck[] =
      args.checks && args.checks.length > 0
        ? args.checks as PreflightCheck[]
        : ALL_CHECKS

    const type = args.type || "feature"
    const sourceDir = context.directory || "."
    const lines: string[] = [
      "DevOps Pre-flight Check",
      "=======================",
      "",
    ]

    let issueTitle = ""
    let branchName = ""
    let workspacePath = ""
    let anyFailed = false

    // Run checks in order
    let step = 1
    for (const check of checksToRun) {
      switch (check) {
        case "issue": {
          lines.push(`${step}. Issue Check`)
          lines.push("   -----------")
          const issueResult = await checkIssue(args.issue_number)
          lines.push(...issueResult.lines)
          issueTitle = issueResult.title
          if (!issueResult.pass) {
            anyFailed = true
            lines.push("")
            lines.push("Pre-flight FAILED. Cannot proceed without a valid issue.")
            return lines.join("\n")
          }
          lines.push("")
          break
        }

        case "clean": {
          lines.push(`${step}. Clean Tree Check`)
          lines.push("   ----------------")
          // Check the main working tree is clean before cloning
          const cleanResult = await checkClean()
          lines.push(...cleanResult.lines)
          if (!cleanResult.pass) {
            anyFailed = true
            lines.push("")
            lines.push("Pre-flight FAILED. Clean the working tree first.")
            return lines.join("\n")
          }
          lines.push("")
          break
        }

        case "branch": {
          lines.push(`${step}. Workspace + Branch Check`)
          lines.push("   ------------------------")
          const branchResult = await checkBranch(
            args.issue_number,
            issueTitle,
            type,
            sourceDir,
          )
          lines.push(...branchResult.lines)
          branchName = branchResult.branchName
          workspacePath = branchResult.workspacePath
          if (!branchResult.pass) {
            anyFailed = true
            lines.push("")
            lines.push("Pre-flight FAILED.")
            return lines.join("\n")
          }
          lines.push("")
          break
        }

        case "plan": {
          lines.push(`${step}. Plan Check`)
          lines.push("   ----------")
          if (args.skip_plan_check) {
            lines.push("   SKIP: Plan check skipped by user.")
          } else {
            const planResult = await checkPlan(args.issue_number)
            lines.push(...planResult.lines)
          }
          lines.push("")
          break
        }
      }
      step++
    }

    // Determine overall result
    const hasWarning = lines.some((l) => l.includes("WARN:"))
    const overallResult = anyFailed
      ? "Pre-flight FAILED."
      : hasWarning
        ? "Pre-flight PASSED with warnings. Review warnings before proceeding."
        : "Pre-flight PASSED. Ready to proceed."

    lines.push("=======================")
    lines.push(overallResult)
    lines.push("")
    lines.push(`Issue     : #${args.issue_number} -- ${issueTitle}`)
    if (branchName) lines.push(`Branch    : ${branchName}`)
    if (workspacePath) {
      lines.push(`Workspace : ${workspacePath}`)
      lines.push("")
      lines.push("IMPORTANT: All subsequent operations (file edits, git commands,")
      lines.push("builds, tests) MUST use this workspace path. Pass it as the")
      lines.push("'workspace' parameter to git tools, or use it as 'workdir'")
      lines.push("for bash commands.")
    }

    return lines.join("\n")
  },
})

// ─── Test Validation ─────────────────────────────────────────────────

type ProjectType = "node" | "go" | "python" | "rust" | "java" | "generic"

function detectProjectType(root: string): ProjectType {
  if (existsSync(`${root}/package.json`)) return "node"
  if (existsSync(`${root}/go.mod`)) return "go"
  if (existsSync(`${root}/pyproject.toml`) || existsSync(`${root}/requirements.txt`)) return "python"
  if (existsSync(`${root}/Cargo.toml`)) return "rust"
  if (existsSync(`${root}/pom.xml`) || existsSync(`${root}/build.gradle`)) return "java"
  return "generic"
}

function autoDetectTestCommand(pt: ProjectType): string | null {
  const commands: Record<ProjectType, string | null> = {
    node: "npm test",
    go: "go test ./...",
    python: "python3 -m pytest",
    rust: "cargo test",
    java: null, // too variable (maven vs gradle)
    generic: null,
  }
  return commands[pt]
}

export const validate_tests = tool({
  description:
    "Run test validation before committing. Detects available test " +
    "infrastructure in priority order: make local-test -> make test -> " +
    "auto-detect by project type. Returns PASS, FAIL, or WARN with " +
    "structured output and options for the user. Supports running in " +
    "an isolated workspace.",
  args: {
    workspace: tool.schema
      .string()
      .optional()
      .describe(
        "Path to an agent workspace (clone). When provided, tests run " +
        "inside the workspace instead of the main project directory.",
      ),
  },
  async execute(args, context) {
    const root = args.workspace || context.directory || "."
    const lines: string[] = [
      "Test Validation",
      "===============",
      "",
    ]

    // Detection priority:
    // 1. make local-test
    // 2. make test
    // 3. auto-detect by project type

    // Check if Makefile exists and has test targets
    const hasMakefile = existsSync(`${root}/Makefile`)
    let testCommand: string | null = null
    let testSource = ""

    if (hasMakefile) {
      // Check for local-test target
      const localTestCheck = args.workspace
        ? await runInDir(["make", "-n", "local-test"], root)
        : await run(["make", "-n", "local-test"])
      if (localTestCheck.ok) {
        testCommand = "make local-test"
        testSource = "Makefile target: local-test"
      } else {
        // Check for test target
        const testCheck = args.workspace
          ? await runInDir(["make", "-n", "test"], root)
          : await run(["make", "-n", "test"])
        if (testCheck.ok) {
          testCommand = "make test"
          testSource = "Makefile target: test"
        }
      }
    }

    // Fallback: auto-detect by project type
    if (!testCommand) {
      const pt = detectProjectType(root)
      const autoCmd = autoDetectTestCommand(pt)
      if (autoCmd) {
        testCommand = autoCmd
        testSource = `auto-detected (${pt})`
      }
    }

    // No test infrastructure found -> WARN
    if (!testCommand) {
      lines.push("Result: WARN")
      lines.push("")
      lines.push("No test infrastructure was found.")
      lines.push("")
      lines.push("Searched for:")
      lines.push("  1. make local-test  (not found)")
      lines.push("  2. make test        (not found)")
      lines.push("  3. Auto-detect      (no known test command for this project type)")
      lines.push("")
      lines.push("Options:")
      lines.push("  1. Proceed without test validation (requires explicit user confirmation)")
      lines.push("  2. Create a tracking issue to add test infrastructure")
      lines.push("  3. Abort and add tests before committing")
      lines.push("")
      lines.push("The user MUST explicitly confirm before proceeding without tests.")

      return lines.join("\n")
    }

    // Run the detected tests
    lines.push(`Detected: ${testSource}`)
    lines.push(`Command : ${testCommand}`)
    lines.push("")

    const cmdParts = testCommand.split(" ")
    const result = args.workspace
      ? await runInDir(cmdParts, root)
      : await run(cmdParts)

    if (result.ok) {
      // PASS
      lines.push("Result: PASS")
      lines.push("")
      lines.push("Tests passed. Proceeding to commit.")
      if (result.out) {
        lines.push("")
        lines.push("Output:")
        // Limit output to last 30 lines to avoid flooding
        const outputLines = result.out.split("\n")
        const tail = outputLines.length > 30
          ? outputLines.slice(-30)
          : outputLines
        if (outputLines.length > 30) {
          lines.push(`  ... (${outputLines.length - 30} lines truncated)`)
        }
        for (const l of tail) lines.push(`  ${l}`)
      }
    } else {
      // FAIL
      lines.push("Result: FAIL")
      lines.push("")
      lines.push("Tests failed. Review the output below.")
      lines.push("")
      lines.push("Output:")
      const outputLines = result.out.split("\n")
      const tail = outputLines.length > 50
        ? outputLines.slice(-50)
        : outputLines
      if (outputLines.length > 50) {
        lines.push(`  ... (${outputLines.length - 50} lines truncated)`)
      }
      for (const l of tail) lines.push(`  ${l}`)
      lines.push("")
      lines.push("Options:")
      lines.push("  1. Fix the failing tests and re-run validation")
      lines.push("  2. Skip test validation (requires explicit user confirmation -- not recommended)")
      lines.push("  3. Abort the commit")
      lines.push("")
      lines.push("The user MUST explicitly confirm before skipping failed tests.")
    }

    return lines.join("\n")
  },
})
