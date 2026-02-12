/**
 * Deploy Contract Skill (Stub)
 *
 * Deploys a compiled Compact contract to Midnight Network.
 * This is a stub implementation - full implementation requires:
 * - Midnight.js SDK integration
 * - Wallet connection (Lace wallet)
 * - Proof Server for ZK proof generation
 */

import type { Message } from '@a2a-js/sdk';
import type { SkillEvent } from './index.js';
import { extractTextFromMessage } from './index.js';

/**
 * Deploy a Compact contract (stub)
 */
export async function* deployContract(
  message: Message
): AsyncGenerator<SkillEvent, void, unknown> {
  const userText = extractTextFromMessage(message);

  yield { type: 'status', message: 'Analyzing deployment request...' };

  // Detect network from message
  const lower = userText.toLowerCase();
  const network = lower.includes('preprod') ? 'preprod' : 'preview';

  yield {
    type: 'status',
    message: `Target network: ${network}`,
  };

  // This is a stub - deployment requires:
  // 1. Compiled contract artifacts (from compile skill)
  // 2. Midnight.js SDK for transaction creation
  // 3. Wallet connection for signing
  // 4. Proof Server for ZK proof generation

  yield {
    type: 'artifact',
    name: 'deploy-info.json',
    content: JSON.stringify(
      {
        status: 'not_implemented',
        message: 'Contract deployment is not yet implemented',
        requirements: [
          'Compiled contract artifacts (.js, .d.ts, contract-info.json)',
          'Midnight.js SDK (@midnight-ntwrk/midnight-js-contracts)',
          'Wallet connection (Lace Midnight wallet)',
          'Proof Server (for ZK proof generation)',
        ],
        network,
        documentation:
          'https://docs.midnight.network/next/midnight-js/deploying',
      },
      null,
      2
    ),
    mimeType: 'application/json',
  };

  yield {
    type: 'result',
    data: {
      implemented: false,
      network,
    },
    message:
      'Contract deployment is not yet implemented. This skill requires Midnight.js SDK integration, wallet connection, and Proof Server setup.',
  };
}
