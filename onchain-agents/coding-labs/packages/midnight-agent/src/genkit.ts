/**
 * Genkit + Vertex AI Initialization
 *
 * Sets up Genkit with Vertex AI for LLM capabilities.
 * Reads configuration from environment variables.
 */

import { genkit } from 'genkit';
import { vertexAI } from '@genkit-ai/vertexai';

// LLM configuration from environment
const project =
  process.env.MIDNIGHT_AGENT_LLM_PROJECT ||
  process.env.GOOGLE_CLOUD_PROJECT ||
  'kunal-scratch';

const location =
  process.env.MIDNIGHT_AGENT_LLM_LOCATION ||
  process.env.GOOGLE_CLOUD_LOCATION ||
  'us-central1';

const model = process.env.MIDNIGHT_AGENT_LLM_MODEL || 'gemini-2.0-flash';

// Genkit instance
export const ai = genkit({
  plugins: [
    vertexAI({
      projectId: project,
      location: location,
    }),
  ],
});

// Model reference for generation
export const geminiModel = `vertexai/${model}`;

/**
 * Initialize Genkit
 * Called at startup to ensure the AI is ready
 */
export async function initializeGenkit(): Promise<void> {
  console.log(`[midnight-agent] Genkit initialized with Vertex AI`);
  console.log(`[midnight-agent]   Project: ${project}`);
  console.log(`[midnight-agent]   Location: ${location}`);
  console.log(`[midnight-agent]   Model: ${model}`);
}
