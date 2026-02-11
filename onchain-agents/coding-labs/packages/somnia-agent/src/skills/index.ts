import type { Message } from '@a2a-js/sdk';
import type { WalletContext } from '@coding-labs/shared';
import { generateSolidity, type SolidityGenResult } from './solidity-gen.js';

/**
 * Skill handler function type
 */
export type SkillHandler = (
  userMessage: Message,
  walletContext?: WalletContext
) => AsyncGenerator<SkillEvent, void, unknown>;

/**
 * Skill event types emitted during execution
 */
export type SkillEvent =
  | { type: 'status'; message: string }
  | { type: 'artifact'; name: string; content: string; mimeType?: string }
  | { type: 'result'; data: unknown }
  | { type: 'error'; message: string };

/**
 * Extract text content from a message
 */
export function extractTextFromMessage(message: Message): string {
  return message.parts
    .filter((p): p is { kind: 'text'; text: string } => p.kind === 'text')
    .map((p) => p.text)
    .join('\n');
}

/**
 * Skill registry mapping skill IDs to handlers
 */
export const skillHandlers: Record<string, SkillHandler> = {
  'solidity-gen': generateSolidity,
  // Phase 2: Add these handlers
  // 'deploy': deployContract,
  // 'tx-status': checkTxStatus,
  // 'query-state': queryState,
  // Phase 3: Add these handlers
  // 'reactivity-setup': setupReactivity,
  // 'data-streams': generateDataStreams,
};

/**
 * Get the appropriate skill handler based on user intent
 * For MVP, we default to solidity-gen
 */
export function detectSkill(userMessage: string): string {
  const lowerMessage = userMessage.toLowerCase();

  // Simple keyword matching for MVP
  if (
    lowerMessage.includes('deploy') ||
    lowerMessage.includes('publish') ||
    lowerMessage.includes('send to')
  ) {
    return 'deploy';
  }

  if (
    lowerMessage.includes('status') ||
    lowerMessage.includes('transaction') ||
    lowerMessage.includes('tx ')
  ) {
    return 'tx-status';
  }

  if (
    lowerMessage.includes('balance') ||
    lowerMessage.includes('query') ||
    lowerMessage.includes('read') ||
    lowerMessage.includes('get ')
  ) {
    return 'query-state';
  }

  if (
    lowerMessage.includes('reactivity') ||
    lowerMessage.includes('subscribe') ||
    lowerMessage.includes('event')
  ) {
    return 'reactivity-setup';
  }

  if (
    lowerMessage.includes('stream') ||
    lowerMessage.includes('data stream')
  ) {
    return 'data-streams';
  }

  // Default to code generation
  return 'solidity-gen';
}

export { generateSolidity, type SolidityGenResult };
