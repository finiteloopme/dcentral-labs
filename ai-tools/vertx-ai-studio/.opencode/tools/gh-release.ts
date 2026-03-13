import { tool } from "@opencode-ai/plugin"
import { ensureEnvironment } from "./git-ops-init"

async function ghRun(args: string[]): Promise<string> {
  const envErr = await ensureEnvironment()
  if (envErr) return envErr

  try {
    const result = await Bun.$`gh ${args}`.text()
    return result.trim()
  } catch (e: any) {
    const stderr = e?.stderr?.toString?.()?.trim() || ""
    return `Error: ${stderr || e.message || "unknown error"}`
  }
}

export const create = tool({
  description:
    "Create a new GitHub release. Can auto-generate release notes from commits.",
  args: {
    tag: tool.schema.string().describe("Tag name for the release (e.g., 'v1.0.0')"),
    title: tool.schema
      .string()
      .optional()
      .describe("Release title (defaults to tag name)"),
    notes: tool.schema
      .string()
      .optional()
      .describe("Release notes in markdown"),
    draft: tool.schema
      .boolean()
      .optional()
      .describe("Create as draft release (default: false)"),
    prerelease: tool.schema
      .boolean()
      .optional()
      .describe("Mark as pre-release (default: false)"),
    generate_notes: tool.schema
      .boolean()
      .optional()
      .describe("Auto-generate release notes from commits (default: false)"),
    target: tool.schema
      .string()
      .optional()
      .describe("Target branch or commit SHA (default: default branch)"),
  },
  async execute(args) {
    const flags: string[] = ["release", "create", args.tag]

    if (args.title) flags.push("--title", args.title)
    if (args.notes) flags.push("--notes", args.notes)
    if (args.draft) flags.push("--draft")
    if (args.prerelease) flags.push("--prerelease")
    if (args.generate_notes) flags.push("--generate-notes")
    if (args.target) flags.push("--target", args.target)

    // If neither notes nor generate_notes, auto-generate
    if (!args.notes && !args.generate_notes) {
      flags.push("--generate-notes")
    }

    return await ghRun(flags)
  },
})

export const list = tool({
  description: "List recent releases.",
  args: {
    limit: tool.schema
      .number()
      .optional()
      .describe("Max number of releases to show (default: 10)"),
  },
  async execute(args) {
    const raw = await ghRun([
      "release",
      "list",
      "--limit",
      String(args.limit || 10),
    ])
    if (raw.startsWith("Error:") || raw.includes("FATAL:")) return raw

    return raw || "No releases found."
  },
})

export const view = tool({
  description: "View details of a specific release.",
  args: {
    tag: tool.schema.string().describe("Tag name of the release to view"),
  },
  async execute(args) {
    return await ghRun(["release", "view", args.tag])
  },
})

export const delete_release = tool({
  description:
    "Delete a release. Optionally also delete the associated git tag. " +
    "This is a destructive operation.",
  args: {
    tag: tool.schema.string().describe("Tag name of the release to delete"),
    cleanup_tag: tool.schema
      .boolean()
      .optional()
      .describe("Also delete the git tag (default: false)"),
  },
  async execute(args) {
    const flags: string[] = ["release", "delete", args.tag, "--yes"]
    if (args.cleanup_tag) flags.push("--cleanup-tag")

    return await ghRun(flags)
  },
})

export const generate_notes = tool({
  description:
    "Generate release notes from commits between two tags or from a tag to HEAD. " +
    "Does NOT create a release, just generates the notes text.",
  args: {
    tag: tool.schema
      .string()
      .describe("Tag name to generate notes for"),
    previous_tag: tool.schema
      .string()
      .optional()
      .describe("Previous tag to generate notes from (default: previous release)"),
  },
  async execute(args) {
    const flags: string[] = [
      "api",
      "repos/{owner}/{repo}/releases/generate-notes",
      "-f",
      `tag_name=${args.tag}`,
    ]
    if (args.previous_tag) {
      flags.push("-f", `previous_tag_name=${args.previous_tag}`)
    }

    const raw = await ghRun(flags)
    if (raw.startsWith("Error:") || raw.includes("FATAL:")) return raw

    try {
      const parsed = JSON.parse(raw)
      return `## ${parsed.name || args.tag}\n\n${parsed.body || "No notes generated."}`
    } catch {
      return raw
    }
  },
})
