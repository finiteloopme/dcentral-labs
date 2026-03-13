import { tool } from "@opencode-ai/plugin"

async function tfRun(args: string[]): Promise<string> {
  try {
    const result = await Bun.$`terraform ${args}`.text()
    return result.trim()
  } catch (e: any) {
    const stderr = e?.stderr?.toString?.()?.trim() || ""
    return `Error: ${stderr || e.message || "unknown error"}`
  }
}

export const init = tool({
  description:
    "Initialize a Terraform working directory. Downloads providers and " +
    "sets up the backend. Safe to run multiple times.",
  args: {
    upgrade: tool.schema
      .boolean()
      .optional()
      .describe("Upgrade modules and providers to latest allowed versions"),
    backend_config: tool.schema
      .string()
      .optional()
      .describe("Backend config value in KEY=VALUE format"),
    reconfigure: tool.schema
      .boolean()
      .optional()
      .describe("Reconfigure backend, ignoring any saved configuration"),
  },
  async execute(args) {
    const flags: string[] = ["init"]
    if (args.upgrade) flags.push("-upgrade")
    if (args.backend_config) flags.push(`-backend-config=${args.backend_config}`)
    if (args.reconfigure) flags.push("-reconfigure")

    return await tfRun(flags)
  },
})

export const validate = tool({
  description: "Validate Terraform configuration files for syntax and consistency.",
  args: {},
  async execute() {
    return await tfRun(["validate"])
  },
})

export const fmt = tool({
  description:
    "Format Terraform configuration files to canonical style. " +
    "Use check=true to only verify formatting without making changes.",
  args: {
    check: tool.schema
      .boolean()
      .optional()
      .describe("Check formatting without modifying files (default: false)"),
    recursive: tool.schema
      .boolean()
      .optional()
      .describe("Process files in subdirectories (default: false)"),
  },
  async execute(args) {
    const flags: string[] = ["fmt"]
    if (args.check) flags.push("-check")
    if (args.recursive) flags.push("-recursive")

    const result = await tfRun(flags)
    return result || "All files are properly formatted."
  },
})

export const plan = tool({
  description:
    "Generate and show a Terraform execution plan. Shows what changes " +
    "will be made without applying them. ALWAYS run this before apply.",
  args: {
    target: tool.schema
      .string()
      .optional()
      .describe("Target specific resource (e.g., 'aws_instance.web')"),
    var: tool.schema
      .string()
      .optional()
      .describe("Variable value in KEY=VALUE format"),
    var_file: tool.schema
      .string()
      .optional()
      .describe("Path to variable definitions file"),
    destroy: tool.schema
      .boolean()
      .optional()
      .describe("Generate a destroy plan (default: false)"),
    out: tool.schema
      .string()
      .optional()
      .describe("Save plan to file for later apply"),
  },
  async execute(args) {
    const flags: string[] = ["plan", "-no-color"]
    if (args.target) flags.push(`-target=${args.target}`)
    if (args.var) flags.push(`-var=${args.var}`)
    if (args.var_file) flags.push(`-var-file=${args.var_file}`)
    if (args.destroy) flags.push("-destroy")
    if (args.out) flags.push(`-out=${args.out}`)

    return await tfRun(flags)
  },
})

export const apply = tool({
  description:
    "Apply Terraform changes. WARNING: This modifies real infrastructure. " +
    "Always run 'plan' first and review the output before applying. " +
    "Requires explicit confirmation via the confirm parameter.",
  args: {
    confirm: tool.schema
      .boolean()
      .describe(
        "Set to true to confirm you want to apply. " +
        "MUST be true or the operation is rejected.",
      ),
    plan_file: tool.schema
      .string()
      .optional()
      .describe("Path to a saved plan file from 'plan -out=...'"),
    target: tool.schema
      .string()
      .optional()
      .describe("Target specific resource"),
    var: tool.schema
      .string()
      .optional()
      .describe("Variable value in KEY=VALUE format"),
    var_file: tool.schema
      .string()
      .optional()
      .describe("Path to variable definitions file"),
  },
  async execute(args) {
    if (!args.confirm) {
      return (
        "REFUSED: You must set confirm=true to apply changes. " +
        "Run 'plan' first and review the output before applying."
      )
    }

    const flags: string[] = ["apply", "-auto-approve", "-no-color"]
    if (args.plan_file) {
      // When using a plan file, no other flags should be passed
      return await tfRun(["apply", "-auto-approve", "-no-color", args.plan_file])
    }

    if (args.target) flags.push(`-target=${args.target}`)
    if (args.var) flags.push(`-var=${args.var}`)
    if (args.var_file) flags.push(`-var-file=${args.var_file}`)

    return await tfRun(flags)
  },
})

export const destroy = tool({
  description:
    "Destroy all Terraform-managed infrastructure. WARNING: This is " +
    "destructive and cannot be undone. Requires explicit confirmation.",
  args: {
    confirm: tool.schema
      .boolean()
      .describe(
        "Set to true to confirm destruction. MUST be true or the operation is rejected.",
      ),
    target: tool.schema
      .string()
      .optional()
      .describe("Target specific resource to destroy"),
    var: tool.schema
      .string()
      .optional()
      .describe("Variable value in KEY=VALUE format"),
    var_file: tool.schema
      .string()
      .optional()
      .describe("Path to variable definitions file"),
  },
  async execute(args) {
    if (!args.confirm) {
      return (
        "REFUSED: You must set confirm=true to destroy infrastructure. " +
        "Run 'plan -destroy' first to review what will be destroyed."
      )
    }

    const flags: string[] = ["destroy", "-auto-approve", "-no-color"]
    if (args.target) flags.push(`-target=${args.target}`)
    if (args.var) flags.push(`-var=${args.var}`)
    if (args.var_file) flags.push(`-var-file=${args.var_file}`)

    return await tfRun(flags)
  },
})

export const state_list = tool({
  description: "List all resources in the Terraform state.",
  args: {
    filter: tool.schema
      .string()
      .optional()
      .describe("Filter resources by address pattern"),
  },
  async execute(args) {
    const flags: string[] = ["state", "list"]
    if (args.filter) flags.push(args.filter)

    const result = await tfRun(flags)
    return result || "No resources in state."
  },
})

export const state_show = tool({
  description: "Show details of a specific resource in the Terraform state.",
  args: {
    address: tool.schema
      .string()
      .describe("Resource address (e.g., 'google_compute_instance.web')"),
  },
  async execute(args) {
    return await tfRun(["state", "show", args.address])
  },
})

export const output = tool({
  description: "Show Terraform output values.",
  args: {
    name: tool.schema
      .string()
      .optional()
      .describe("Specific output name (default: show all)"),
    json: tool.schema
      .boolean()
      .optional()
      .describe("Output in JSON format"),
  },
  async execute(args) {
    const flags: string[] = ["output", "-no-color"]
    if (args.json) flags.push("-json")
    if (args.name) flags.push(args.name)

    const result = await tfRun(flags)
    return result || "No outputs defined."
  },
})

export const workspace_list = tool({
  description: "List Terraform workspaces.",
  args: {},
  async execute() {
    return await tfRun(["workspace", "list"])
  },
})

export const workspace_select = tool({
  description: "Switch to a different Terraform workspace.",
  args: {
    name: tool.schema.string().describe("Workspace name to switch to"),
  },
  async execute(args) {
    return await tfRun(["workspace", "select", args.name])
  },
})
