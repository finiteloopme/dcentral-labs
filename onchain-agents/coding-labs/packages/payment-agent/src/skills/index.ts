import type { Message } from '@a2a-js/sdk';
import type { WalletContext } from '@coding-labs/shared';
import { payForOrder } from './pay.js';
import { verifyPayment } from './verify-payment.js';
import { checkPaymentStatus } from './payment-status.js';
import { listSupported } from './supported.js';

export type SkillHandler = (
  userMessage: Message,
  walletContext?: WalletContext
) => AsyncGenerator<SkillEvent, void, unknown>;

export type SkillEvent =
  | { type: 'status'; message: string }
  | { type: 'artifact'; name: string; content: string; mimeType?: string }
  | { type: 'result'; data: unknown }
  | { type: 'error'; message: string };

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

export const skillHandlers: Record<string, SkillHandler> = {
  'pay': payForOrder,
  'verify-payment': verifyPayment,
  'payment-status': checkPaymentStatus,
  'supported': listSupported,
};

/**
 * Detect which skill to use based on user message.
 *
 * Priority:
 *   1. Payment status (specific check)
 *   2. Verify payment (dry-run)
 *   3. Pay (execute payment)
 *   4. Supported (info/help)
 */
export function detectSkill(userMessage: string): string {
  const text = userMessage.toLowerCase();

  // 1. Payment status
  if (
    text.includes('status') ||
    text.includes('check payment') ||
    text.includes('check tx') ||
    text.includes('payment history') ||
    text.includes('my payments')
  ) {
    return 'payment-status';
  }

  // 2. Verify
  if (
    text.includes('verify') ||
    text.includes('validate') ||
    text.includes('check if') ||
    text.includes('can i pay') ||
    text.includes('dry run')
  ) {
    return 'verify-payment';
  }

  // 3. Pay
  if (
    text.includes('pay') ||
    text.includes('settle') ||
    text.includes('send') ||
    text.includes('transfer') ||
    text.includes('checkout') ||
    text.includes('complete') ||
    text.includes('order') ||
    text.includes('ord_')
  ) {
    return 'pay';
  }

  // 4. Default to supported
  return 'supported';
}
