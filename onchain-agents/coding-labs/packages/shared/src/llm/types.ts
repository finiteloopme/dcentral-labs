/**
 * LLM provider configuration
 */
export interface LLMConfig {
  provider: 'vertex-ai' | 'openai' | 'anthropic';
  model: string;
  project?: string;
  location?: string;
  apiKey?: string;
}

/**
 * Default Vertex AI configuration
 */
export const DEFAULT_VERTEX_CONFIG: LLMConfig = {
  provider: 'vertex-ai',
  model: 'gemini-2.5-flash',
  project: 'kunal-scratch',
  location: 'global',
};

/**
 * Code generation output format
 */
export interface CodeFile {
  filename: string;
  content: string;
  language?: string;
}

/**
 * Code generation response
 */
export interface CodeGenerationResponse {
  files: CodeFile[];
  explanation?: string;
}
