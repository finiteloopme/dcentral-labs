import type { Message } from '@a2a-js/sdk';
import type { WalletContext } from '@coding-labs/shared';
import type { SkillEvent } from './index.js';
import { extractTextFromMessage } from './index.js';
import { getPaymentRecord, getAllPayments } from '../x402-client.js';

export async function* checkPaymentStatus(
  userMessage: Message,
  _walletContext?: WalletContext
): AsyncGenerator<SkillEvent, void, unknown> {
  yield { type: 'status', message: 'Checking payment status...' };

  const text = extractTextFromMessage(userMessage);

  // Check for specific payment ID
  const paymentMatch = text.match(/pay_[a-z0-9]+/i);
  // Order ID and tx hash could be used for future lookups
  // const orderMatch = text.match(/ord_[a-z0-9]+/i);
  // const txMatch = text.match(/0x[a-fA-F0-9]{64}/);

  if (paymentMatch) {
    const record = getPaymentRecord(paymentMatch[0]);
    if (!record) {
      yield {
        type: 'error',
        message: `Payment \`${paymentMatch[0]}\` not found.`,
      };
      return;
    }

    const statusEmoji = {
      pending: '⏳',
      verified: '✔️',
      settled: '✅',
      failed: '❌',
    }[record.status];

    yield {
      type: 'artifact',
      name: 'payment-status.md',
      content:
        `## ${statusEmoji} Payment Status\n\n` +
        `**Payment ID:** \`${paymentMatch[0]}\`\n` +
        `**Order ID:** \`${record.orderId || 'N/A'}\`\n` +
        `**Status:** ${statusEmoji} ${record.status}\n` +
        `**Network:** ${record.paymentOption.network}\n` +
        `**Amount:** ${record.paymentOption.price}\n` +
        `**Pay To:** \`${record.paymentOption.payTo}\`\n` +
        (record.txHash ? `**Transaction:** \`${record.txHash}\`\n` : '') +
        `**Created:** ${record.createdAt}\n` +
        (record.settledAt ? `**Settled:** ${record.settledAt}\n` : ''),
      mimeType: 'text/markdown',
    };

    yield { type: 'result', data: { paymentId: paymentMatch[0], ...record } };
    return;
  }

  // Show all payments
  const allPayments = getAllPayments();

  if (allPayments.length === 0) {
    yield {
      type: 'artifact',
      name: 'payment-status.md',
      content:
        '## 💳 Payment History\n\nNo payments have been made yet.\n\n' +
        'To make a payment, first purchase an item from the **@store** agent.',
      mimeType: 'text/markdown',
    };
    yield { type: 'result', data: { payments: [] } };
    return;
  }

  let output = '## 💳 Payment History\n\n';
  output += '| Payment ID | Order | Amount | Status | Network |\n';
  output += '|-----------|-------|--------|--------|--------|\n';

  for (const payment of allPayments) {
    const emoji = {
      pending: '⏳',
      verified: '✔️',
      settled: '✅',
      failed: '❌',
    }[payment.status];
    output += `| \`${payment.paymentId}\` | \`${payment.orderId || 'N/A'}\` | ${payment.paymentOption.price} | ${emoji} ${payment.status} | ${payment.paymentOption.network} |\n`;
  }

  output += `\n_${allPayments.length} payment(s) total._`;

  yield {
    type: 'artifact',
    name: 'payment-history.md',
    content: output,
    mimeType: 'text/markdown',
  };

  yield { type: 'result', data: { payments: allPayments } };
}
