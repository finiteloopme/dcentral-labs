import { genkit } from 'genkit';
import { vertexAI } from '@genkit-ai/vertexai';

// Read from component-specific env vars (generated from config.toml)
// Falls back to generic env vars for backward compatibility
const projectId =
  process.env.SOMNIA_AGENT_LLM_PROJECT ||
  process.env.GOOGLE_CLOUD_PROJECT ||
  'kunal-scratch';

const location =
  process.env.SOMNIA_AGENT_LLM_LOCATION ||
  process.env.GOOGLE_CLOUD_LOCATION ||
  'us-central1';

const model = process.env.SOMNIA_AGENT_LLM_MODEL || 'gemini-2.0-flash';

// Initialize Genkit with Vertex AI
export const ai = genkit({
  plugins: [vertexAI({ projectId, location })],
  model: `vertexai/${model}`,
});

// Export for use in skills
export { projectId, location, model };
