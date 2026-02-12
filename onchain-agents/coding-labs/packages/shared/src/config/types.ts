/**
 * Configuration Types
 *
 * Type definitions for the centralized config.toml configuration.
 */

/**
 * Service configuration (host, port, optional URL override)
 */
export interface ServiceConfig {
  host: string;
  port: number;
  url?: string; // Explicit URL override (for containers/cloud)
}

/**
 * Agent configuration (for agent-registry)
 */
export interface AgentConfig {
  name: string;
  description: string;
  service: string; // References a service name for URL construction
  chain_id: number;
  keywords: string[];
  enabled: boolean;
  url?: string; // Explicit URL override
}

/**
 * Native currency configuration
 */
export interface NativeCurrency {
  name: string;
  symbol: string;
  decimals: number;
}

/**
 * Network (blockchain) configuration
 */
export interface NetworkConfig {
  chain_id: number;
  name: string;
  rpc_url: string;
  explorer_url: string;
  native_currency: NativeCurrency;
}

/**
 * LLM Provider type identifiers
 */
export type LLMProviderType =
  | 'vertex'
  | 'vertex-anthropic'
  | 'openai'
  | 'anthropic';

/**
 * Individual LLM provider configuration
 */
export interface LLMProviderConfig {
  type: LLMProviderType;
  project?: string; // For Vertex AI providers
  location?: string; // For Vertex AI providers
  model: string;
  api_key_env?: string; // Env var name for API key (future: OpenAI, etc.)
}

/**
 * Full LLM configuration section
 */
export interface LLMConfig {
  default: string; // Default provider name
  providers: Record<string, LLMProviderConfig>; // Named provider definitions
  components: Record<string, string>; // Component -> provider mapping
}

/**
 * Environment-specific configuration section
 */
export interface EnvConfig {
  services?: Record<string, Partial<ServiceConfig>>;
  agents?: Record<string, Partial<AgentConfig>>;
  networks?: Record<string, Partial<NetworkConfig>>;
  llm?: Partial<LLMConfig>;
}

/**
 * Meta information
 */
export interface MetaConfig {
  version: string;
  updated?: string;
}

/**
 * Full configuration file structure
 */
export interface Config {
  meta: MetaConfig;
  default: EnvConfig;
  production?: EnvConfig;
  [env: string]: EnvConfig | MetaConfig | undefined;
}

/**
 * Resolved configuration (after merging defaults + env + env vars)
 */
export interface ResolvedConfig {
  meta: MetaConfig;
  services: Record<string, ServiceConfig>;
  agents: Record<string, AgentConfig & { resolvedUrl: string }>;
  networks: Record<string, NetworkConfig>;
  llm: LLMConfig;
}

/**
 * Agent info returned by registry API
 */
export interface AgentInfo {
  id: string;
  name: string;
  description: string;
  url: string;
  chainId: number;
  keywords: string[];
  enabled: boolean;
}

/**
 * Registry API response
 */
export interface AgentRegistryResponse {
  agents: AgentInfo[];
  version: string;
  updated?: string;
}
