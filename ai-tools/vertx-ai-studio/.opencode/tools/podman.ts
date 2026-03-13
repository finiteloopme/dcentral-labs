import { tool } from "@opencode-ai/plugin"

async function podmanRun(args: string[]): Promise<string> {
  try {
    const result = await Bun.$`podman ${args}`.text()
    return result.trim()
  } catch (e: any) {
    const stderr = e?.stderr?.toString?.()?.trim() || ""
    return `Error: ${stderr || e.message || "unknown error"}`
  }
}

export const build = tool({
  description:
    "Build a container image using Podman. Supports Containerfile and Dockerfile.",
  args: {
    tag: tool.schema.string().describe("Image tag (e.g., 'myapp:latest')"),
    context: tool.schema
      .string()
      .optional()
      .describe("Build context directory (default: '.')"),
    file: tool.schema
      .string()
      .optional()
      .describe("Path to Containerfile/Dockerfile (default: auto-detected)"),
    no_cache: tool.schema
      .boolean()
      .optional()
      .describe("Disable build cache (default: false)"),
    build_arg: tool.schema
      .string()
      .optional()
      .describe("Build argument in KEY=VALUE format"),
    target: tool.schema
      .string()
      .optional()
      .describe("Target build stage for multi-stage builds"),
  },
  async execute(args) {
    const flags: string[] = ["build", "-t", args.tag]
    if (args.file) flags.push("-f", args.file)
    if (args.no_cache) flags.push("--no-cache")
    if (args.build_arg) flags.push("--build-arg", args.build_arg)
    if (args.target) flags.push("--target", args.target)
    flags.push(args.context || ".")

    return await podmanRun(flags)
  },
})

export const run_container = tool({
  description:
    "Run a container using Podman. Returns the container ID or output.",
  args: {
    image: tool.schema.string().describe("Image name or ID to run"),
    name: tool.schema
      .string()
      .optional()
      .describe("Container name"),
    detach: tool.schema
      .boolean()
      .optional()
      .describe("Run in background (default: false)"),
    port: tool.schema
      .string()
      .optional()
      .describe("Port mapping (e.g., '8080:80')"),
    env: tool.schema
      .string()
      .optional()
      .describe("Environment variable in KEY=VALUE format"),
    volume: tool.schema
      .string()
      .optional()
      .describe("Volume mount (e.g., './data:/data')"),
    rm: tool.schema
      .boolean()
      .optional()
      .describe("Remove container when it exits (default: false)"),
    command: tool.schema
      .string()
      .optional()
      .describe("Command to run inside the container"),
  },
  async execute(args) {
    const flags: string[] = ["run"]
    if (args.detach) flags.push("-d")
    if (args.name) flags.push("--name", args.name)
    if (args.port) flags.push("-p", args.port)
    if (args.env) flags.push("-e", args.env)
    if (args.volume) flags.push("-v", args.volume)
    if (args.rm) flags.push("--rm")
    flags.push(args.image)
    if (args.command) flags.push(...args.command.split(" "))

    return await podmanRun(flags)
  },
})

export const ps = tool({
  description:
    "List running containers. Use all=true to include stopped containers.",
  args: {
    all: tool.schema
      .boolean()
      .optional()
      .describe("Show all containers including stopped (default: false)"),
    format: tool.schema
      .string()
      .optional()
      .describe("Output format (e.g., 'json', 'table')"),
  },
  async execute(args) {
    const flags: string[] = ["ps"]
    if (args.all) flags.push("-a")
    if (args.format) flags.push("--format", args.format)

    const result = await podmanRun(flags)
    return result || "No containers found."
  },
})

export const images = tool({
  description: "List locally available container images.",
  args: {
    filter: tool.schema
      .string()
      .optional()
      .describe("Filter images (e.g., 'reference=myapp')"),
  },
  async execute(args) {
    const flags: string[] = ["images"]
    if (args.filter) flags.push("--filter", args.filter)

    const result = await podmanRun(flags)
    return result || "No images found."
  },
})

export const logs = tool({
  description: "Fetch logs from a container.",
  args: {
    container: tool.schema.string().describe("Container name or ID"),
    tail: tool.schema
      .number()
      .optional()
      .describe("Number of lines to show from the end (default: all)"),
    follow: tool.schema
      .boolean()
      .optional()
      .describe("Follow log output (default: false)"),
    since: tool.schema
      .string()
      .optional()
      .describe("Show logs since timestamp or relative time (e.g., '10m')"),
  },
  async execute(args) {
    const flags: string[] = ["logs"]
    if (args.tail) flags.push("--tail", String(args.tail))
    if (args.since) flags.push("--since", args.since)
    // Do not support --follow in a non-interactive context
    flags.push(args.container)

    return await podmanRun(flags)
  },
})

export const stop = tool({
  description: "Stop a running container.",
  args: {
    container: tool.schema.string().describe("Container name or ID to stop"),
    timeout: tool.schema
      .number()
      .optional()
      .describe("Seconds to wait before killing (default: 10)"),
  },
  async execute(args) {
    const flags: string[] = ["stop"]
    if (args.timeout) flags.push("-t", String(args.timeout))
    flags.push(args.container)

    return await podmanRun(flags)
  },
})

export const rm = tool({
  description:
    "Remove a stopped container. Use force=true to remove a running container.",
  args: {
    container: tool.schema.string().describe("Container name or ID to remove"),
    force: tool.schema
      .boolean()
      .optional()
      .describe("Force remove even if running (default: false)"),
    volumes: tool.schema
      .boolean()
      .optional()
      .describe("Also remove associated volumes (default: false)"),
  },
  async execute(args) {
    const flags: string[] = ["rm"]
    if (args.force) flags.push("-f")
    if (args.volumes) flags.push("-v")
    flags.push(args.container)

    return await podmanRun(flags)
  },
})

export const inspect = tool({
  description:
    "Inspect a container or image for detailed configuration and state.",
  args: {
    target: tool.schema
      .string()
      .describe("Container or image name/ID to inspect"),
    format: tool.schema
      .string()
      .optional()
      .describe("Go template format string to extract specific fields"),
  },
  async execute(args) {
    const flags: string[] = ["inspect"]
    if (args.format) flags.push("--format", args.format)
    flags.push(args.target)

    return await podmanRun(flags)
  },
})

export const exec = tool({
  description: "Execute a command inside a running container.",
  args: {
    container: tool.schema.string().describe("Container name or ID"),
    command: tool.schema.string().describe("Command to execute inside the container"),
    interactive: tool.schema
      .boolean()
      .optional()
      .describe("Keep STDIN open (default: false)"),
    workdir: tool.schema
      .string()
      .optional()
      .describe("Working directory inside the container"),
  },
  async execute(args) {
    const flags: string[] = ["exec"]
    if (args.interactive) flags.push("-i")
    if (args.workdir) flags.push("-w", args.workdir)
    flags.push(args.container)
    flags.push(...args.command.split(" "))

    return await podmanRun(flags)
  },
})
