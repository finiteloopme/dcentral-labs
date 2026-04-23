/**
 * LLM Configuration - AI SDK + Vertex AI Anthropic
 *
 * Provides Claude models via Google Vertex AI using the AI SDK.
 * Authentication uses Google ADC (gcloud auth application-default login
 * or GOOGLE_APPLICATION_CREDENTIALS env var).
 */

import { createVertexAnthropic } from '@ai-sdk/google-vertex/anthropic';
import type { LanguageModel } from 'ai';

// Read from component-specific env vars (generated from config.toml)
const projectId =
  process.env.MIDNIGHT_AGENT_LLM_PROJECT ||
  process.env.GOOGLE_CLOUD_PROJECT ||
  'kunal-scratch';

const location =
  process.env.MIDNIGHT_AGENT_LLM_LOCATION ||
  process.env.GOOGLE_CLOUD_LOCATION ||
  'global';

const modelId = process.env.MIDNIGHT_AGENT_LLM_MODEL || 'claude-opus-4-5';

// Create the Vertex Anthropic provider
const vertexAnthropic = createVertexAnthropic({
  project: projectId,
  location: location,
});

// Export model instance for use in skills
export const model: LanguageModel = vertexAnthropic(modelId);

// Export config for logging
export { projectId, location, modelId };

console.log(`[midnight-agent] LLM initialized with Vertex AI Anthropic`);
console.log(`[midnight-agent]   Project: ${projectId}`);
console.log(`[midnight-agent]   Location: ${location}`);
console.log(`[midnight-agent]   Model: ${modelId}`);
