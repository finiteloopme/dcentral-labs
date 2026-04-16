/**
 * LLM Model Factory
 *
 * Creates AI SDK LanguageModel instances based on config.toml settings.
 * Auto-detects the correct Vertex AI provider (Google or Anthropic)
 * from the provider type configuration.
 */

import { createVertex } from '@ai-sdk/google-vertex';
import { createVertexAnthropic } from '@ai-sdk/google-vertex/anthropic';
import type { LanguageModel } from 'ai';
import { loadConfigFile, getLLMConfig, getLLMConfigForComponent } from '../config/index.js';

/**
 * Convert a component name to an environment variable prefix.
 * e.g., "sonic-agent" → "SONIC_AGENT"
 */
function toEnvPrefix(componentName: string): string {
  return componentName.toUpperCase().replace(/-/g, '_');
}

/**
 * Create a LanguageModel for a named component using config.toml settings.
 *
 * Resolution order:
 *   1. config.toml [default.llm.components] → provider mapping
 *   2. config.toml [default.llm.providers.<name>] → provider config (type, project, location, model)
 *   3. Environment variables override (e.g., SONIC_AGENT_LLM_MODEL, SONIC_AGENT_LLM_PROJECT)
 *
 * @param componentName - The component name as defined in config.toml (e.g., "sonic-agent")
 * @returns A configured LanguageModel instance
 */
export function createModelForComponent(componentName: string): LanguageModel {
  const config = loadConfigFile();
  const llmConfig = getLLMConfig(config);
  const providerConfig = getLLMConfigForComponent(llmConfig, componentName);

  if (!providerConfig) {
    throw new Error(
      `No LLM provider configured for component "${componentName}". ` +
      `Check config.toml [default.llm.components] and [default.llm.providers].`
    );
  }

  const prefix = toEnvPrefix(componentName);

  // Environment variable overrides take precedence
  const project = process.env[`${prefix}_LLM_PROJECT`] || process.env.GOOGLE_CLOUD_PROJECT || providerConfig.project;
  const location = process.env[`${prefix}_LLM_LOCATION`] || process.env.GOOGLE_CLOUD_LOCATION || providerConfig.location;
  const model = process.env[`${prefix}_LLM_MODEL`] || providerConfig.model;

  console.log(`[shared/llm] Creating model for ${componentName}: type=${providerConfig.type}, model=${model}, project=${project}, location=${location}`);

  switch (providerConfig.type) {
    case 'vertex': {
      const vertex = createVertex({ project, location });
      return vertex(model);
    }
    case 'vertex-anthropic': {
      const anthropic = createVertexAnthropic({ project, location });
      return anthropic(model);
    }
    default:
      throw new Error(
        `Unknown LLM provider type "${providerConfig.type}" for component "${componentName}". ` +
        `Supported types: "vertex", "vertex-anthropic"`
      );
  }
}
