import type { Message } from '@a2a-js/sdk';
import type { WalletContext } from '@coding-labs/shared';
import { generateSolidity } from './solidity-gen.js';
import { compileSkill } from './compile.js';
import { deploySkill } from './deploy.js';
import { callSkill } from './call.js';
import { txStatusSkill } from './tx-status.js';
import { feemInfoSkill } from './feem.js';

/**
 * Skill handler function type
 */
export type SkillHandler = (
  userMessage: Message,
  walletContext?: WalletContext,
  sessionId?: string
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
  compile: compileSkill,
  deploy: deploySkill,
  call: callSkill,
  'tx-status': txStatusSkill,
  'feem-info': feemInfoSkill,
};

/**
 * Get the appropriate skill handler based on user intent.
 *
 * Priority order:
 *   1. Code generation (most common)
 *   2. Compile
 *   3. Deploy
 *   4. Call
 *   5. Transaction status
 *   6. FeeM info
 *   7. Default → code generation
 */
export function detectSkill(userMessage: string): string {
  const text = userMessage.toLowerCase();

  // 1. Code generation
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

  // 2. Compile
  if (text.includes('compile') || text.includes('build this')) {
    return 'compile';
  }

  // 3. Deploy
  if (text.includes('deploy') || text.includes('publish contract')) {
    return 'deploy';
  }

  // 4. Call
  if (
    text.includes('call ') ||
    text.includes('read from') ||
    text.includes('get balance') ||
    text.includes('total supply') ||
    text.includes('balanceof') ||
    text.includes('owner of')
  ) {
    return 'call';
  }

  // 5. Transaction status
  if (
    text.includes('status') ||
    text.includes('transaction') ||
    text.includes('tx ') ||
    text.includes('receipt')
  ) {
    return 'tx-status';
  }

  // 6. FeeM info
  if (
    text.includes('feem') ||
    text.includes('fee monetization') ||
    text.includes('earn fees') ||
    text.includes('gas fees') ||
    text.includes('developer rewards')
  ) {
    return 'feem-info';
  }

  // Default to code generation
  return 'solidity-gen';
}

export { generateSolidity } from './solidity-gen.js';
export { compileSkill } from './compile.js';
export { deploySkill } from './deploy.js';
export { callSkill } from './call.js';
export { txStatusSkill } from './tx-status.js';
export { feemInfoSkill } from './feem.js';
