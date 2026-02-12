/**
 * Configuration Loader
 *
 * Loads and resolves configuration from config.toml with environment variable overrides.
 *
 * Resolution order (later wins):
 *   1. [default.*] sections (base configuration)
 *   2. [<env>.*] sections (environment-specific overrides)
 *   3. Environment variables (container/cloud overrides)
 */

import { existsSync, readFileSync } from 'fs';
import { parse } from 'smol-toml';
import { resolve } from 'path';
import type {
  Config,
  EnvConfig,
  ResolvedConfig,
  ServiceConfig,
  AgentConfig,
  NetworkConfig,
  LLMConfig,
  LLMProviderConfig,
  AgentInfo,
} from './types.js';

// Default config file locations to search
const CONFIG_SEARCH_PATHS = [
  'config.toml',
  '../config.toml',
  '../../config.toml',
  '../../../config.toml',
];

/**
 * Convert service name to environment variable prefix
 * e.g., "somnia-agent" → "SOMNIA_AGENT"
 */
export function toEnvPrefix(serviceName: string): string {
  return serviceName.toUpperCase().replace(/-/g, '_');
}

/**
 * Find the config.toml file by searching up from the current directory
 */
export function findConfigPath(startDir?: string): string | null {
  const baseDir = startDir || process.cwd();

  for (const searchPath of CONFIG_SEARCH_PATHS) {
    const fullPath = resolve(baseDir, searchPath);
    if (existsSync(fullPath)) {
      return fullPath;
    }
  }

  return null;
}

/**
 * Load raw config from TOML file
 */
export function loadConfigFile(configPath?: string): Config {
  const path = configPath || findConfigPath();

  if (!path) {
    throw new Error(
      'config.toml not found. Searched paths: ' + CONFIG_SEARCH_PATHS.join(', ')
    );
  }

  const content = readFileSync(path, 'utf-8');
  return parse(content) as unknown as Config;
}

/**
 * Deep merge two objects (simple version for our config structure)
 */
function mergeObjects<T>(base: T, override: Partial<T> | undefined): T {
  if (!override) return base;

  const result = { ...base };

  for (const key of Object.keys(override) as Array<keyof T>) {
    const overrideValue = override[key];
    if (overrideValue !== undefined) {
      result[key] = overrideValue as T[keyof T];
    }
  }

  return result;
}

/**
 * Get environment-specific config section
 */
function getEnvSection(config: Config, env: string): EnvConfig | undefined {
  if (env === 'production' && config.production) {
    return config.production;
  }
  // For other environments, check if they exist as dynamic keys
  const envSection = config[env];
  if (
    envSection &&
    typeof envSection === 'object' &&
    'services' in envSection
  ) {
    return envSection as EnvConfig;
  }
  return undefined;
}

/**
 * Get service configuration with environment variable overrides
 */
export function getServiceConfig(
  config: Config,
  serviceName: string,
  env: string = process.env.NODE_ENV || 'development'
): ServiceConfig {
  // Start with defaults
  const defaultConfig = config.default?.services?.[serviceName];
  if (!defaultConfig) {
    throw new Error(`Service "${serviceName}" not found in config.toml`);
  }

  // Cast to ServiceConfig
  const baseConfig: ServiceConfig = {
    host: defaultConfig.host as string,
    port: defaultConfig.port as number,
    url: defaultConfig.url as string | undefined,
  };

  // Merge environment-specific overrides
  const envSection = getEnvSection(config, env);
  const envServiceConfig = envSection?.services?.[serviceName];
  let merged = mergeObjects(
    baseConfig,
    envServiceConfig as Partial<ServiceConfig>
  );

  // Apply environment variable overrides
  const prefix = toEnvPrefix(serviceName);

  if (process.env[`${prefix}_HOST`]) {
    merged = { ...merged, host: process.env[`${prefix}_HOST`]! };
  }
  if (process.env[`${prefix}_PORT`]) {
    merged = { ...merged, port: parseInt(process.env[`${prefix}_PORT`]!, 10) };
  }
  if (process.env[`${prefix}_URL`]) {
    merged = { ...merged, url: process.env[`${prefix}_URL`]! };
  }

  return merged;
}

/**
 * Construct service URL from host and port
 */
export function getServiceUrl(service: ServiceConfig): string {
  if (service.url) {
    return service.url;
  }
  const protocol = service.port === 443 ? 'https' : 'http';
  return `${protocol}://${service.host}:${service.port}`;
}

/**
 * Get agent configuration with resolved URL
 */
export function getAgentConfig(
  config: Config,
  agentId: string,
  env: string = process.env.NODE_ENV || 'development'
): AgentConfig & { resolvedUrl: string } {
  // Start with defaults
  const defaultAgentConfig = config.default?.agents?.[agentId];
  if (!defaultAgentConfig) {
    throw new Error(`Agent "${agentId}" not found in config.toml`);
  }

  // Cast to AgentConfig
  const baseConfig: AgentConfig = {
    name: defaultAgentConfig.name as string,
    description: defaultAgentConfig.description as string,
    service: defaultAgentConfig.service as string,
    chain_id: defaultAgentConfig.chain_id as number,
    keywords: defaultAgentConfig.keywords as string[],
    enabled: defaultAgentConfig.enabled as boolean,
    url: defaultAgentConfig.url as string | undefined,
  };

  // Merge environment-specific overrides
  const envSection = getEnvSection(config, env);
  const envAgentConfig = envSection?.agents?.[agentId];
  let merged = mergeObjects(baseConfig, envAgentConfig as Partial<AgentConfig>);

  // Check for explicit URL override from environment
  const prefix = toEnvPrefix(merged.service);
  const envUrl = process.env[`${prefix}_URL`];

  if (envUrl) {
    merged = { ...merged, url: envUrl };
  }

  // Resolve the URL
  let resolvedUrl: string;
  if (merged.url) {
    resolvedUrl = merged.url;
  } else {
    const serviceConfig = getServiceConfig(config, merged.service, env);
    resolvedUrl = getServiceUrl(serviceConfig);
  }

  return { ...merged, resolvedUrl };
}

/**
 * Get all agents as AgentInfo array (for registry API)
 */
export function getAllAgents(
  config: Config,
  env: string = process.env.NODE_ENV || 'development'
): AgentInfo[] {
  const agents: AgentInfo[] = [];
  const agentIds = Object.keys(config.default?.agents || {});

  for (const id of agentIds) {
    const agent = getAgentConfig(config, id, env);
    agents.push({
      id,
      name: agent.name,
      description: agent.description,
      url: agent.resolvedUrl,
      chainId: agent.chain_id,
      keywords: agent.keywords,
      enabled: agent.enabled,
    });
  }

  return agents;
}

/**
 * Get enabled agents only
 */
export function getEnabledAgents(
  config: Config,
  env: string = process.env.NODE_ENV || 'development'
): AgentInfo[] {
  return getAllAgents(config, env).filter((agent) => agent.enabled);
}

/**
 * Get network configuration
 */
export function getNetworkConfig(
  config: Config,
  networkId: string,
  env: string = process.env.NODE_ENV || 'development'
): NetworkConfig {
  const defaultNetworkConfig = config.default?.networks?.[networkId];
  if (!defaultNetworkConfig) {
    throw new Error(`Network "${networkId}" not found in config.toml`);
  }

  // Cast to NetworkConfig
  const nc = defaultNetworkConfig.native_currency as {
    name: string;
    symbol: string;
    decimals: number;
  };
  const baseConfig: NetworkConfig = {
    chain_id: defaultNetworkConfig.chain_id as number,
    name: defaultNetworkConfig.name as string,
    rpc_url: defaultNetworkConfig.rpc_url as string,
    explorer_url: defaultNetworkConfig.explorer_url as string,
    native_currency: {
      name: nc?.name || '',
      symbol: nc?.symbol || '',
      decimals: nc?.decimals || 18,
    },
  };

  const envSection = getEnvSection(config, env);
  const envNetworkConfig = envSection?.networks?.[networkId];

  return mergeObjects(baseConfig, envNetworkConfig as Partial<NetworkConfig>);
}

/**
 * Get LLM configuration
 */
export function getLLMConfig(
  config: Config,
  _env: string = process.env.NODE_ENV || 'development'
): LLMConfig {
  const defaultLLMConfig = config.default?.llm as {
    default?: string;
    providers?: Record<string, unknown>;
    components?: Record<string, string>;
  };

  if (!defaultLLMConfig) {
    throw new Error('LLM configuration not found in config.toml');
  }

  // Parse providers
  const providers: Record<string, LLMProviderConfig> = {};
  const rawProviders = defaultLLMConfig.providers || {};

  for (const [name, rawProvider] of Object.entries(rawProviders)) {
    const provider = rawProvider as {
      type: string;
      project?: string;
      location?: string;
      model: string;
      api_key_env?: string;
    };
    providers[name] = {
      type: provider.type as LLMProviderConfig['type'],
      project: provider.project,
      location: provider.location,
      model: provider.model,
      api_key_env: provider.api_key_env,
    };
  }

  // Parse components
  const components: Record<string, string> = defaultLLMConfig.components || {};

  return {
    default: defaultLLMConfig.default || '',
    providers,
    components,
  };
}

/**
 * Get LLM provider config for a specific component.
 * Falls back to default provider if component not explicitly assigned.
 * Returns null if provider is "none" or not found.
 */
export function getLLMConfigForComponent(
  llmConfig: LLMConfig,
  componentName: string
): LLMProviderConfig | null {
  const providerName = llmConfig.components[componentName] ?? llmConfig.default;
  if (!providerName || providerName === 'none') return null;
  return llmConfig.providers[providerName] ?? null;
}

/**
 * Get the provider name assigned to a component.
 */
export function getLLMProviderName(
  llmConfig: LLMConfig,
  componentName: string
): string | null {
  return llmConfig.components[componentName] ?? llmConfig.default ?? null;
}

/**
 * Load and resolve full configuration
 */
export function loadConfig(
  configPath?: string,
  env: string = process.env.NODE_ENV || 'development'
): ResolvedConfig {
  const config = loadConfigFile(configPath);

  // Resolve all services
  const services: Record<string, ServiceConfig> = {};
  for (const serviceName of Object.keys(config.default?.services || {})) {
    services[serviceName] = getServiceConfig(config, serviceName, env);
  }

  // Resolve all agents
  const agents: Record<string, AgentConfig & { resolvedUrl: string }> = {};
  for (const agentId of Object.keys(config.default?.agents || {})) {
    agents[agentId] = getAgentConfig(config, agentId, env);
  }

  // Resolve all networks
  const networks: Record<string, NetworkConfig> = {};
  for (const networkId of Object.keys(config.default?.networks || {})) {
    networks[networkId] = getNetworkConfig(config, networkId, env);
  }

  // Resolve LLM config
  const llm = getLLMConfig(config, env);

  return {
    meta: config.meta,
    services,
    agents,
    networks,
    llm,
  };
}

/**
 * Singleton config instance for convenience
 */
let _configInstance: ResolvedConfig | null = null;

export function getConfig(): ResolvedConfig {
  if (!_configInstance) {
    _configInstance = loadConfig();
  }
  return _configInstance;
}

export function resetConfig(): void {
  _configInstance = null;
}
