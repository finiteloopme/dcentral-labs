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
 * Detect which skill should handle a message based on content analysis.
 *
 * Priority order:
 *   1. Code generation (most common, shares vocabulary with other skills)
 *   2. Compile (explicit "compile" or code block provided)
 *   3. Deploy
 *   4. Call circuit
 *   5. Query state (tightened patterns to avoid false positives)
 *   6. Private state
 *   7. Default → code generation
 */
export function detectSkill(userText: string): string {
  const text = userText.toLowerCase();

  // 1. Code generation - check FIRST since generation requests naturally
  //    contain words like "ledger", "state", "circuit" that overlap other skills
  if (
    text.includes('generate') ||
    text.includes('create') ||
    text.includes('write') ||
    text.includes('build me') ||
    text.includes('make a') ||
    text.includes('make me') ||
    text.includes('implement') ||
    text.includes('code for') ||
    text.includes('contract for') ||
    text.includes('contract that') ||
    text.includes('contract with') ||
    text.includes('smart contract') ||
    text.includes('write a') ||
    text.includes('design a')
  ) {
    return 'compact-gen';
  }

  // 2. Compile - only when user explicitly asks to compile existing code
  if (
    text.includes('compile') ||
    text.includes('.compact file') ||
    text.includes('```compact')
  ) {
    return 'compile';
  }

  // 3. Deploy
  if (text.includes('deploy') || text.includes('publish contract')) {
    return 'deploy';
  }

  // 4. Call circuit
  if (
    text.includes('call circuit') ||
    text.includes('execute circuit') ||
    text.includes('run circuit') ||
    text.includes('invoke circuit')
  ) {
    return 'call';
  }

  // 5. Query state - specific patterns only, avoid generic words
  //    that appear in code generation requests
  if (
    text.includes('query state') ||
    text.includes('query contract') ||
    text.includes('query ledger') ||
    text.includes('get state of') ||
    text.includes('read state of') ||
    text.includes('read ledger of') ||
    text.includes('check state') ||
    text.includes('what is the state') ||
    (text.includes('query') && /0x[a-fA-F0-9]{40,}/.test(text))
  ) {
    return 'query-state';
  }

  // 6. Private state
  if (
    text.includes('private state') ||
    text.includes('manage private') ||
    text.includes('local state')
  ) {
    return 'private-state';
  }

  // Default to code generation
  return 'compact-gen';
}
