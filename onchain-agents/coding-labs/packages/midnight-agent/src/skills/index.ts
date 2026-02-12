/**
 * Midnight Agent Skills Registry
 *
 * Defines skill types, handlers, and detection logic.
 */

import type { Message } from '@a2a-js/sdk';
import { generateCompact } from './compact-gen.js';
import { compileCompact } from './compile.js';
import { queryState } from './query-state.js';
import { deployContract } from './deploy.js';
import { callCircuit } from './call.js';
import { managePrivateState } from './private-state.js';

/**
 * Events emitted by skill handlers during execution
 */
export type SkillEvent =
  | { type: 'status'; message: string }
  | { type: 'artifact'; name: string; content: string; mimeType?: string }
  | { type: 'result'; data: unknown; message?: string }
  | { type: 'error'; message: string };

/**
 * Skill handler function signature
 */
export type SkillHandler = (
  message: Message
) => AsyncGenerator<SkillEvent, void, unknown>;

/**
 * Map of skill IDs to their handler functions
 */
export const skillHandlers: Record<string, SkillHandler> = {
  'compact-gen': generateCompact,
  compile: compileCompact,
  'query-state': queryState,
  deploy: deployContract,
  call: callCircuit,
  'private-state': managePrivateState,
};

/**
 * Extract text content from a message
 * Handles both A2A SDK format (kind: 'text') and raw JSON format (type: 'text')
 */
export function extractTextFromMessage(message: Message): string {
  return message.parts
    .filter((p) => {
      const part = p as { kind?: string; type?: string };
      return part.kind === 'text' || part.type === 'text';
    })
    .map((p) => {
      const part = p as { text?: string };
      return part.text ?? '';
    })
    .join('\n');
}

/**
 * Detect which skill should handle a message based on content analysis
 */
export function detectSkill(userText: string): string {
  const text = userText.toLowerCase();

  // Compile skill detection
  if (
    text.includes('compile') ||
    (text.includes('build') && text.includes('compact')) ||
    text.includes('.compact file')
  ) {
    return 'compile';
  }

  // Deploy skill detection
  if (text.includes('deploy') || text.includes('publish contract')) {
    return 'deploy';
  }

  // Call circuit detection
  if (
    text.includes('call circuit') ||
    text.includes('execute circuit') ||
    text.includes('run circuit') ||
    text.includes('invoke circuit')
  ) {
    return 'call';
  }

  // Query state detection
  if (
    text.includes('query') ||
    text.includes('get state') ||
    text.includes('read ledger') ||
    text.includes('current value') ||
    text.includes('ledger state')
  ) {
    return 'query-state';
  }

  // Private state detection
  if (
    text.includes('private state') ||
    text.includes('private key') ||
    text.includes('witness') ||
    text.includes('local state')
  ) {
    return 'private-state';
  }

  // Default to code generation for anything else
  return 'compact-gen';
}
