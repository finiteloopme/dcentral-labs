import type { Message } from '@a2a-js/sdk';
import type { WalletContext } from '@coding-labs/shared';
import type { SkillEvent } from './index.js';
import { extractTextFromMessage } from './index.js';
import { getOrder, updateOrderStatus } from './purchase.js';

export async function* confirmPurchase(
  userMessage: Message,
  _walletContext?: WalletContext
): AsyncGenerator<SkillEvent, void, unknown> {
  yield { type: 'status', message: 'Verifying your purchase...' };

  const text = extractTextFromMessage(userMessage);

  // Extract order ID
  const orderMatch = text.match(/ord_[a-z0-9]+/i);
  const orderId = orderMatch?.[0];

  // Extract transaction hash
  const txMatch = text.match(/0x[a-fA-F0-9]{64}/);
  const txHash = txMatch?.[0];

  if (!orderId) {
    yield {
      type: 'error',
      message: 'Please provide your order ID (e.g., "confirm order ord_abc12345 with tx 0x...").',
    };
    return;
  }

  const order = getOrder(orderId);
  if (!order) {
    yield {
      type: 'error',
      message: `Order \`${orderId}\` not found. Please check the order ID and try again.`,
    };
    return;
  }

  if (order.status === 'confirmed') {
    yield {
      type: 'artifact',
      name: 'confirmation.md',
      content: `## ✅ Order Already Confirmed\n\n**Order ID:** \`${orderId}\`\n**Item:** ${order.itemName}\n**Status:** Confirmed`,
      mimeType: 'text/markdown',
    };
    yield { type: 'result', data: { orderId, status: 'already_confirmed' } };
    return;
  }

  if (!txHash) {
    yield {
      type: 'error',
      message: `Order \`${orderId}\` found (${order.itemName}, $${order.priceUSDC} USDC) but no transaction hash provided. Please include your payment transaction hash: "confirm order ${orderId} with tx 0x..."`,
    };
    return;
  }

  // In a real implementation, we would verify the transaction on-chain
  // For this mock, we accept any valid-looking tx hash
  updateOrderStatus(orderId, 'confirmed');

  const confirmation = `## ✅ Purchase Confirmed!\n\n` +
    `**Order ID:** \`${orderId}\`\n` +
    `**Item:** ${order.itemName}\n` +
    `**Amount Paid:** $${order.priceUSDC} USDC\n` +
    `**Transaction:** \`${txHash}\`\n` +
    `**Status:** ✅ Confirmed\n` +
    `**Confirmed At:** ${new Date().toISOString()}\n\n` +
    `Thank you for your purchase! 🎉`;

  yield {
    type: 'artifact',
    name: 'confirmation.md',
    content: confirmation,
    mimeType: 'text/markdown',
  };

  yield {
    type: 'result',
    data: {
      orderId,
      item: order.itemName,
      amountUSDC: order.priceUSDC,
      txHash,
      status: 'confirmed',
    },
  };
}
