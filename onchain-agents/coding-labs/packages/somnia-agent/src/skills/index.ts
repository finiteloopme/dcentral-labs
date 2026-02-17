import type { Message } from '@a2a-js/sdk';
import type { WalletContext } from '@coding-labs/shared';
import { generateSolidity, type SolidityGenResult } from './solidity-gen.js';
import { deployContract } from './deploy.js';
import { checkTxStatus } from './tx-status.js';
import { queryState } from './query-state.js';

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
 * Skill registry mapping skill IDs to handlers
 */
export const skillHandlers: Record<string, SkillHandler> = {
  'solidity-gen': generateSolidity,
  deploy: deployContract,
  'tx-status': checkTxStatus,
  'query-state': queryState,
  // Phase 3: Add these handlers
  // 'reactivity-setup': setupReactivity,
  // 'data-streams': generateDataStreams,
};

/**
 * Get the appropriate skill handler based on user intent.
 *
 * Priority order:
 *   1. Code generation (most common, shares vocabulary with other skills)
 *   2. Deploy
 *   3. Transaction status
 *   4. Query state (tightened to avoid false positives)
 *   5. Reactivity / data streams (Phase 3)
 *   6. Default → code generation
 */
export function detectSkill(userMessage: string): string {
  const text = userMessage.toLowerCase();

  // 1. Code generation - check FIRST since generation requests naturally
  //    contain words like "read", "get", "event" that overlap other skills
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
    text.includes('design a') ||
    text.includes('solidity') ||
    text.includes('erc-20') ||
    text.includes('erc20') ||
    text.includes('erc-721') ||
    text.includes('erc721') ||
    text.includes('token contract') ||
    text.includes('nft contract')
  ) {
    return 'solidity-gen';
  }

  // 2. Deploy
  if (text.includes('deploy') || text.includes('publish contract')) {
    return 'deploy';
  }

  // 3. Transaction status
  if (
    text.includes('status') ||
    text.includes('transaction') ||
    text.includes('tx ') ||
    text.includes('receipt')
  ) {
    return 'tx-status';
  }

  // 4. Query state - specific patterns, avoid generic "read", "get", "query"
  if (
    text.includes('balance') ||
    text.includes('query state') ||
    text.includes('query contract') ||
    text.includes('get state of') ||
    text.includes('read state') ||
    text.includes('check state') ||
    text.includes('total supply') ||
    text.includes('what is the') ||
    (text.includes('query') && /0x[a-fA-F0-9]{40,}/.test(text))
  ) {
    return 'query-state';
  }

  // 5. Reactivity (Phase 3)
  if (text.includes('reactivity') || text.includes('subscribe to')) {
    return 'reactivity-setup';
  }

  // 6. Data streams (Phase 3)
  if (text.includes('data stream')) {
    return 'data-streams';
  }

  // Default to code generation
  return 'solidity-gen';
}

export { generateSolidity, type SolidityGenResult };
export { deployContract } from './deploy.js';
export { checkTxStatus } from './tx-status.js';
export { queryState } from './query-state.js';
