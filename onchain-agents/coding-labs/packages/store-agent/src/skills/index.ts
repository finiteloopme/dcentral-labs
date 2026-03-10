import type { Message } from '@a2a-js/sdk';
import type { WalletContext } from '@coding-labs/shared';
import { browseCatalog } from './browse.js';
import { getItemDetail } from './item-detail.js';
import { purchaseItem } from './purchase.js';
import { confirmPurchase } from './confirm.js';

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
  'browse': browseCatalog,
  'item-detail': getItemDetail,
  'purchase': purchaseItem,
  'confirm': confirmPurchase,
};

/**
 * Detect which skill to use based on user message.
 *
 * Priority order:
 *   1. Purchase (buy/order intent)
 *   2. Confirm (payment confirmation)
 *   3. Item detail (specific item query)
 *   4. Browse (default - catalog browsing)
 */
export function detectSkill(userMessage: string): string {
  const text = userMessage.toLowerCase();

  // 1. Confirm - check first since it's very specific
  if (
    text.includes('confirm') ||
    text.includes('verify payment') ||
    text.includes('receipt') ||
    (text.includes('order') && text.includes('status'))
  ) {
    return 'confirm';
  }

  // 2. Purchase
  if (
    text.includes('buy') ||
    text.includes('purchase') ||
    text.includes('order') ||
    text.includes('i want') ||
    text.includes('i\'d like') ||
    text.includes('add to cart') ||
    text.includes('checkout')
  ) {
    return 'purchase';
  }

  // 3. Item detail - specific item inquiry
  if (
    text.includes('detail') ||
    text.includes('tell me about') ||
    text.includes('how much') ||
    text.includes('price of') ||
    text.includes('info on') ||
    text.includes('information about') ||
    text.includes('describe')
  ) {
    return 'item-detail';
  }

  // 4. Default to browse
  return 'browse';
}
