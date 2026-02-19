#!/usr/bin/env bun
/**
 * Generate .env.generated from config.toml
 *
 * This script reads the master config.toml and generates environment variables
 * for use with docker-compose/podman-compose.
 *
 * Usage:
 *   bun scripts/generate-env.ts [--env=production]
 */

import { readFileSync, writeFileSync } from 'fs';
import { parse } from 'smol-toml';
import { resolve } from 'path';

// Types matching the config structure
interface ServiceConfig {
  host: string;
  port: number;
  url?: string;
}

interface AgentConfig {
  name: string;
  description: string;
  service: string;
  chain_id: number;
  keywords: string[];
  enabled: boolean;
  url?: string;
}

interface LLMProviderConfig {
  type: string;
  project?: string;
  location?: string;
  model: string;
  api_key_env?: string;
}

interface LLMConfig {
  default?: string;
  providers?: Record<string, LLMProviderConfig>;
  components?: Record<string, string>;
}

interface A2AConfig {
  default_agents?: string[];
}

interface EnvSection {
  services?: Record<string, Partial<ServiceConfig>>;
  agents?: Record<string, Partial<AgentConfig>>;
  llm?: Partial<LLMConfig>;
  a2a?: A2AConfig;
}

interface Config {
  meta: { version: string; updated?: string };
  default: EnvSection;
  production?: EnvSection;
  [key: string]: unknown;
}

/**
 * Convert service name to env var prefix
 */
function toEnvPrefix(name: string): string {
  return name.toUpperCase().replace(/-/g, '_');
}

/**
 * Construct URL from host and port
 */
function constructUrl(host: string, port: number): string {
  const protocol = port === 443 ? 'https' : 'http';
  return `${protocol}://${host}:${port}`;
}

/**
 * Merge base config with environment-specific overrides
 */
function mergeConfigs<T>(base: T, override?: Partial<T>): T {
  if (!override) return base;
  return { ...base, ...override };
}

/**
 * Main generation function
 */
function generateEnv(env: string = 'development'): string {
  const configPath = resolve(process.cwd(), 'config.toml');
  const content = readFileSync(configPath, 'utf-8');
  const config = parse(content) as unknown as Config;

  const lines: string[] = [
    '# Auto-generated from config.toml - DO NOT EDIT',
    `# Generated: ${new Date().toISOString()}`,
    `# Environment: ${env}`,
    '# Run: bun scripts/generate-env.ts',
    '',
  ];

  // Get environment-specific overrides
  const envSection = env === 'production' ? config.production : undefined;

  // Generate service variables
  lines.push(
    '# ============================================================================='
  );
  lines.push('# SERVICES');
  lines.push(
    '# ============================================================================='
  );
  lines.push('');

  const services = config.default?.services || {};
  for (const [name, baseService] of Object.entries(services)) {
    const envOverride = envSection?.services?.[name];
    const service = mergeConfigs(baseService as ServiceConfig, envOverride);
    const prefix = toEnvPrefix(name);

    lines.push(`# ${name}`);
    lines.push(`${prefix}_HOST=${service.host}`);
    lines.push(`${prefix}_PORT=${service.port}`);
    lines.push(
      `${prefix}_URL=${service.url || constructUrl(service.host, service.port)}`
    );
    lines.push('');
  }

  // Generate agent variables (for registry to use)
  lines.push(
    '# ============================================================================='
  );
  lines.push('# AGENTS');
  lines.push(
    '# ============================================================================='
  );
  lines.push('');

  const agents = config.default?.agents || {};
  for (const [id, baseAgent] of Object.entries(agents)) {
    const envOverride = envSection?.agents?.[id];
    const agent = mergeConfigs(baseAgent as AgentConfig, envOverride);

    if (!agent.enabled) continue;

    // Get the service config to construct URL
    const serviceName = agent.service;
    const baseService = services[serviceName] as ServiceConfig | undefined;
    const serviceOverride = envSection?.services?.[serviceName];
    const service = baseService
      ? mergeConfigs(baseService, serviceOverride)
      : null;

    const prefix = toEnvPrefix(serviceName);
    const url =
      agent.url || (service ? constructUrl(service.host, service.port) : '');

    lines.push(`# ${agent.name} (${id})`);
    lines.push(`${prefix}_URL=${url}`);
    lines.push('');
  }

  // Generate LLM variables
  lines.push(
    '# ============================================================================='
  );
  lines.push('# LLM PROVIDERS');
  lines.push(
    '# ============================================================================='
  );
  lines.push('');

  const llmConfig = config.default?.llm;
  const llmProviders = llmConfig?.providers || {};
  const llmComponents = llmConfig?.components || {};
  const llmDefault = llmConfig?.default || '';

  lines.push(`# Default provider: ${llmDefault}`);
  lines.push('');

  // Track OpenCode's provider for special env vars
  let opencodeProvider: LLMProviderConfig | null = null;
  let defaultProvider: LLMProviderConfig | null = null;

  if (llmDefault && llmProviders[llmDefault]) {
    defaultProvider = llmProviders[llmDefault];
  }

  // Generate component-specific LLM env vars
  lines.push(
    '# ============================================================================='
  );
  lines.push('# LLM - COMPONENT ASSIGNMENTS');
  lines.push(
    '# ============================================================================='
  );
  lines.push('');

  for (const [componentName, providerName] of Object.entries(llmComponents)) {
    const provider = llmProviders[providerName];
    if (!provider) continue;

    const prefix = toEnvPrefix(componentName);

    lines.push(`# ${componentName} → ${providerName}`);
    lines.push(`${prefix}_LLM_TYPE=${provider.type}`);
    if (provider.project)
      lines.push(`${prefix}_LLM_PROJECT=${provider.project}`);
    if (provider.location)
      lines.push(`${prefix}_LLM_LOCATION=${provider.location}`);
    lines.push(`${prefix}_LLM_MODEL=${provider.model}`);
    lines.push('');

    if (componentName === 'opencode') {
      opencodeProvider = provider;
    }
  }

  // Generate OpenCode-specific env vars (it reads VERTEX_LOCATION, GOOGLE_CLOUD_PROJECT)
  lines.push(
    '# OpenCode-specific (reads VERTEX_LOCATION, GOOGLE_CLOUD_PROJECT)'
  );
  const ocProvider = opencodeProvider || defaultProvider;
  if (ocProvider) {
    lines.push(`GOOGLE_CLOUD_PROJECT=${ocProvider.project || ''}`);
    lines.push(`VERTEX_LOCATION=${ocProvider.location || ''}`);
  }

  // Also set GOOGLE_CLOUD_LOCATION for OpenCode (it reads this first before VERTEX_LOCATION)
  if (ocProvider?.location) {
    lines.push(`GOOGLE_CLOUD_LOCATION=${ocProvider.location}`);
  }
  lines.push('');

  // Generate A2A config variables
  lines.push(
    '# ============================================================================='
  );
  lines.push('# A2A (Agent-to-Agent) CONFIG');
  lines.push(
    '# ============================================================================='
  );
  lines.push('');

  const a2aConfig = config.default?.a2a;
  const a2aEnvOverride = envSection?.a2a;
  const defaultAgents =
    a2aEnvOverride?.default_agents || a2aConfig?.default_agents || [];

  if (defaultAgents.length > 0) {
    lines.push(`# Default blockchain agents for A2A routing`);
    lines.push(`A2A_DEFAULT_AGENTS=${defaultAgents.join(',')}`);
  }
  lines.push('');

  return lines.join('\n');
}

// Parse command line arguments
const args = process.argv.slice(2);
let env = 'development';

for (const arg of args) {
  if (arg.startsWith('--env=')) {
    env = arg.split('=')[1];
  }
}

// Generate and write
const output = generateEnv(env);
const outputPath = resolve(process.cwd(), '.env.generated');

writeFileSync(outputPath, output);
console.log(`Generated ${outputPath} for environment: ${env}`);
console.log('');
console.log('Usage in compose.yaml:');
console.log('  env_file:');
console.log('    - .env.generated');
