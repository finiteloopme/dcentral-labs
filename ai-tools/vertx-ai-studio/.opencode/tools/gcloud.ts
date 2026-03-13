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

export const auth_status = tool({
  description:
    "Check the current gcloud authentication status. Shows the active " +
    "account, project, and region.",
  args: {},
  async execute() {
    const lines: string[] = ["Google Cloud Authentication Status", "==================================", ""]

    // Active account
    try {
      const account = await Bun.$`gcloud auth list --filter=status:ACTIVE --format=value(account)`.text()
      lines.push(`Active account : ${account.trim() || "none"}`)
    } catch {
      lines.push("Active account : NOT AUTHENTICATED")
      lines.push("")
      lines.push("Run `gcloud auth login` to authenticate.")
      return lines.join("\n")
    }

    // Project
    try {
      const project = await Bun.$`gcloud config get-value project`.text()
      lines.push(`Project        : ${project.trim() || "not set"}`)
    } catch {
      lines.push("Project        : not set")
    }

    // Region
    try {
      const region = await Bun.$`gcloud config get-value compute/region`.text()
      lines.push(`Region         : ${region.trim() || "not set"}`)
    } catch {
      lines.push("Region         : not set")
    }

    // Zone
    try {
      const zone = await Bun.$`gcloud config get-value compute/zone`.text()
      lines.push(`Zone           : ${zone.trim() || "not set"}`)
    } catch {
      lines.push("Zone           : not set")
    }

    return lines.join("\n")
  },
})

export const project_info = tool({
  description: "Get information about the current or specified GCP project.",
  args: {
    project: tool.schema
      .string()
      .optional()
      .describe("Project ID (default: current project)"),
  },
  async execute(args) {
    const flags: string[] = ["projects", "describe"]
    if (args.project) {
      flags.push(args.project)
    } else {
      // Get current project
      try {
        const project = await Bun.$`gcloud config get-value project`.text()
        const p = project.trim()
        if (!p) return "Error: No project set. Run `gcloud config set project PROJECT_ID`."
        flags.push(p)
      } catch {
        return "Error: Could not determine current project."
      }
    }

    return await gcloudRun(flags)
  },
})

export const compute_list = tool({
  description: "List Compute Engine VM instances.",
  args: {
    project: tool.schema
      .string()
      .optional()
      .describe("Project ID (default: current project)"),
    filter: tool.schema
      .string()
      .optional()
      .describe("Filter expression (e.g., 'status=RUNNING')"),
    format: tool.schema
      .string()
      .optional()
      .describe("Output format (e.g., 'table', 'json', 'yaml')"),
  },
  async execute(args) {
    const flags: string[] = ["compute", "instances", "list"]
    if (args.project) flags.push("--project", args.project)
    if (args.filter) flags.push("--filter", args.filter)
    if (args.format) flags.push("--format", args.format)

    const result = await gcloudRun(flags)
    return result || "No VM instances found."
  },
})

export const gke_clusters = tool({
  description: "List GKE (Google Kubernetes Engine) clusters.",
  args: {
    project: tool.schema
      .string()
      .optional()
      .describe("Project ID (default: current project)"),
    region: tool.schema
      .string()
      .optional()
      .describe("Region to list clusters in (default: all regions)"),
    format: tool.schema
      .string()
      .optional()
      .describe("Output format (e.g., 'table', 'json')"),
  },
  async execute(args) {
    const flags: string[] = ["container", "clusters", "list"]
    if (args.project) flags.push("--project", args.project)
    if (args.region) flags.push("--region", args.region)
    if (args.format) flags.push("--format", args.format)

    const result = await gcloudRun(flags)
    return result || "No GKE clusters found."
  },
})

export const run_services = tool({
  description: "List Cloud Run services.",
  args: {
    project: tool.schema
      .string()
      .optional()
      .describe("Project ID (default: current project)"),
    region: tool.schema
      .string()
      .optional()
      .describe("Region (default: all regions)"),
    format: tool.schema
      .string()
      .optional()
      .describe("Output format"),
  },
  async execute(args) {
    const flags: string[] = ["run", "services", "list"]
    if (args.project) flags.push("--project", args.project)
    if (args.region) flags.push("--region", args.region)
    if (args.format) flags.push("--format", args.format)

    const result = await gcloudRun(flags)
    return result || "No Cloud Run services found."
  },
})

export const logs_read = tool({
  description:
    "Read log entries from Cloud Logging. Supports filtering and limiting.",
  args: {
    filter: tool.schema
      .string()
      .optional()
      .describe(
        "Log filter expression (e.g., 'resource.type=gce_instance AND severity>=ERROR')",
      ),
    limit: tool.schema
      .number()
      .optional()
      .describe("Maximum number of entries to return (default: 20)"),
    project: tool.schema
      .string()
      .optional()
      .describe("Project ID (default: current project)"),
    freshness: tool.schema
      .string()
      .optional()
      .describe("How far back to look (e.g., '1h', '30m', '1d')"),
    format: tool.schema
      .string()
      .optional()
      .describe("Output format"),
  },
  async execute(args) {
    const flags: string[] = ["logging", "read"]
    if (args.filter) flags.push(args.filter)
    flags.push("--limit", String(args.limit || 20))
    if (args.project) flags.push("--project", args.project)
    if (args.freshness) flags.push("--freshness", args.freshness)
    if (args.format) flags.push("--format", args.format)

    return await gcloudRun(flags)
  },
})

export const iam_roles = tool({
  description:
    "List IAM policy bindings for the current or specified project.",
  args: {
    project: tool.schema
      .string()
      .optional()
      .describe("Project ID (default: current project)"),
    format: tool.schema
      .string()
      .optional()
      .describe("Output format (default: table)"),
  },
  async execute(args) {
    const flags: string[] = ["projects", "get-iam-policy"]

    if (args.project) {
      flags.push(args.project)
    } else {
      try {
        const project = await Bun.$`gcloud config get-value project`.text()
        const p = project.trim()
        if (!p) return "Error: No project set. Run `gcloud config set project PROJECT_ID`."
        flags.push(p)
      } catch {
        return "Error: Could not determine current project."
      }
    }

    if (args.format) flags.push("--format", args.format)

    return await gcloudRun(flags)
  },
})

export const config_list = tool({
  description: "List all active gcloud configuration properties.",
  args: {},
  async execute() {
    return await gcloudRun(["config", "list"])
  },
})

export const services_list = tool({
  description: "List enabled APIs/services for the project.",
  args: {
    project: tool.schema
      .string()
      .optional()
      .describe("Project ID (default: current project)"),
    filter: tool.schema
      .string()
      .optional()
      .describe("Filter expression"),
  },
  async execute(args) {
    const flags: string[] = ["services", "list", "--enabled"]
    if (args.project) flags.push("--project", args.project)
    if (args.filter) flags.push("--filter", args.filter)

    return await gcloudRun(flags)
  },
})
