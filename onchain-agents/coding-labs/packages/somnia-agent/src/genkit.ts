import { genkit } from 'genkit';
import { vertexAI } from '@genkit-ai/vertexai';

// Initialize Genkit with Vertex AI
export const ai = genkit({
  plugins: [
    vertexAI({
      projectId: process.env.GOOGLE_CLOUD_PROJECT || 'kunal-scratch',
      location: process.env.GOOGLE_CLOUD_LOCATION || 'global',
    }),
  ],
  model: 'vertexai/gemini-2.5-flash',
});
