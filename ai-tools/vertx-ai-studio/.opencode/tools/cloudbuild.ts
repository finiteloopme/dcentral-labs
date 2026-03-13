import { tool } from "@opencode-ai/plugin"

async function gcloudRun(args: string[]): Promise<string> {
  try {
    const result = await Bun.$`gcloud ${args}`.text()
    return result.trim()
  } catch (e: any) {
    const stderr = e?.stderr?.toString?.()?.trim() || ""
    return `Error: ${stderr || e.message || "unknown error"}`
  }
}

export const submit = tool({
  description:
    "Submit a build to Cloud Build. Specify a cloudbuild.yaml config " +
    "and optional substitution variables.",
  args: {
    config: tool.schema
      .string()
      .optional()
      .describe("Path to cloudbuild.yaml (default: 'cicd/cloudbuild.yaml')"),
    source: tool.schema
      .string()
      .optional()
      .describe("Source directory to upload (default: '.')"),
    substitutions: tool.schema
      .string()
      .optional()
      .describe("Substitution variables as KEY=VALUE,KEY=VALUE"),
    project: tool.schema
      .string()
      .optional()
      .describe("GCP project ID (default: current project)"),
    region: tool.schema
      .string()
      .optional()
      .describe("Cloud Build region (default: global)"),
  },
  async execute(args) {
    const flags: string[] = ["builds", "submit"]

    flags.push("--config", args.config || "cicd/cloudbuild.yaml")

    if (args.substitutions) flags.push("--substitutions", args.substitutions)
    if (args.project) flags.push("--project", args.project)
    if (args.region) flags.push("--region", args.region)

    flags.push(args.source || ".")

    return await gcloudRun(flags)
  },
})

export const list_builds = tool({
  description: "List recent Cloud Build builds with status and timing.",
  args: {
    limit: tool.schema
      .number()
      .optional()
      .describe("Max number of builds to list (default: 10)"),
    project: tool.schema
      .string()
      .optional()
      .describe("GCP project ID (default: current project)"),
    region: tool.schema
      .string()
      .optional()
      .describe("Cloud Build region (default: global)"),
    filter: tool.schema
      .string()
      .optional()
      .describe("Filter expression (e.g., 'status=SUCCESS')"),
  },
  async execute(args) {
    const flags: string[] = [
      "builds",
      "list",
      "--limit",
      String(args.limit || 10),
    ]

    if (args.project) flags.push("--project", args.project)
    if (args.region) flags.push("--region", args.region)
    if (args.filter) flags.push("--filter", args.filter)

    const result = await gcloudRun(flags)
    return result || "No builds found."
  },
})

export const log = tool({
  description: "View logs for a specific Cloud Build build.",
  args: {
    build_id: tool.schema.string().describe("Build ID to fetch logs for"),
    project: tool.schema
      .string()
      .optional()
      .describe("GCP project ID (default: current project)"),
    region: tool.schema
      .string()
      .optional()
      .describe("Cloud Build region (default: global)"),
  },
  async execute(args) {
    const flags: string[] = ["builds", "log", args.build_id]

    if (args.project) flags.push("--project", args.project)
    if (args.region) flags.push("--region", args.region)

    return await gcloudRun(flags)
  },
})

export const triggers_list = tool({
  description: "List configured Cloud Build triggers.",
  args: {
    project: tool.schema
      .string()
      .optional()
      .describe("GCP project ID (default: current project)"),
    region: tool.schema
      .string()
      .optional()
      .describe("Cloud Build region (default: global)"),
  },
  async execute(args) {
    const flags: string[] = ["builds", "triggers", "list"]

    if (args.project) flags.push("--project", args.project)
    if (args.region) flags.push("--region", args.region)

    const result = await gcloudRun(flags)
    return result || "No triggers found."
  },
})

export const triggers_run = tool({
  description: "Manually run a Cloud Build trigger.",
  args: {
    trigger_id: tool.schema
      .string()
      .describe("Trigger ID or name to run"),
    project: tool.schema
      .string()
      .optional()
      .describe("GCP project ID (default: current project)"),
    region: tool.schema
      .string()
      .optional()
      .describe("Cloud Build region (default: global)"),
    branch: tool.schema
      .string()
      .optional()
      .describe("Branch to build (default: trigger's configured branch)"),
  },
  async execute(args) {
    const flags: string[] = ["builds", "triggers", "run", args.trigger_id]

    if (args.project) flags.push("--project", args.project)
    if (args.region) flags.push("--region", args.region)
    if (args.branch) flags.push("--branch", args.branch)

    return await gcloudRun(flags)
  },
})

export const cancel = tool({
  description: "Cancel a running Cloud Build build.",
  args: {
    build_id: tool.schema.string().describe("Build ID to cancel"),
    project: tool.schema
      .string()
      .optional()
      .describe("GCP project ID (default: current project)"),
    region: tool.schema
      .string()
      .optional()
      .describe("Cloud Build region (default: global)"),
  },
  async execute(args) {
    const flags: string[] = ["builds", "cancel", args.build_id]

    if (args.project) flags.push("--project", args.project)
    if (args.region) flags.push("--region", args.region)

    return await gcloudRun(flags)
  },
})
