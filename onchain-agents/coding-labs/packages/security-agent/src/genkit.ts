/**
 * LLM Configuration for Security Agent
 *
 * Uses the shared model factory to create the correct LLM provider
 * based on config.toml settings. For security-agent, config.toml assigns
 * the "vertex-anthropic" provider (Claude via Vertex AI).
 */

import { createModelForComponent } from '@coding-labs/shared/llm';

// Create model from config.toml (respects env var overrides)
export const model = createModelForComponent('security-agent');
