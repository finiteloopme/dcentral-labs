import { v4 as uuidv4 } from 'uuid';
import type { Message } from '@a2a-js/sdk';
import type { WalletContext } from '@coding-labs/shared';
import type { SkillEvent } from './index.js';
import { extractTextFromMessage } from './index.js';
import {
  parsePaymentRequirements,
  createPaymentRecord,
  updatePaymentRecord,
  SUPPORTED_NETWORKS,
} from '../x402-client.js';
import { FACILITATOR_URL } from '../facilitator.js';

export async function* payForOrder(
  userMessage: Message,
  walletContext?: WalletContext
): AsyncGenerator<SkillEvent, void, unknown> {
  yield { type: 'status', message: 'Processing payment request...' };

  const text = extractTextFromMessage(userMessage);

  // Try to parse payment requirements from the message
  const parsed = parsePaymentRequirements(text);

  if (!parsed || !parsed.paymentRequired) {
    // Check if there's an order ID mentioned
    const orderMatch = text.match(/ord_[a-z0-9]+/i);

    if (orderMatch) {
      yield {
        type: 'error',
        message:
          `Found order ID \`${orderMatch[0]}\` but no payment details. ` +
          `Please include the full payment information from the store agent's purchase response, or ` +
          `go back to **@store** and say "buy [item name]" to get the payment details.`,
      };
      return;
    }

    yield {
      type: 'error',
      message:
        'No payment details found in your message. To pay for an order:\n\n' +
        '1. First, tell **@store** to buy an item (e.g., "buy the spiral notebook")\n' +
        '2. Then, copy the payment details and tell me to "pay for order ord_xxxxx"\n\n' +
        'Or say "what networks do you support" to see supported payment options.',
    };
    return;
  }

  const paymentOption = parsed.paymentRequired.accepts[0];
  if (!paymentOption) {
    yield {
      type: 'error',
      message: 'No accepted payment options found in the payment requirements.',
    };
    return;
  }

  // Check wallet connection
  if (!walletContext?.connected) {
    const paymentId = `pay_${uuidv4().slice(0, 8)}`;
    createPaymentRecord(paymentId, paymentOption, parsed.orderId);

    const networkInfo = SUPPORTED_NETWORKS[paymentOption.network];

    yield {
      type: 'artifact',
      name: 'payment-instructions.md',
      content:
        `## 💳 Payment Required\n\n` +
        `**Payment ID:** \`${paymentId}\`\n` +
        `**Order ID:** \`${parsed.orderId || 'N/A'}\`\n` +
        `**Amount:** ${paymentOption.price} USDC\n` +
        `**Network:** ${networkInfo?.name || paymentOption.network}\n` +
        `**Pay To:** \`${paymentOption.payTo}\`\n` +
        `**Asset (USDC):** \`${paymentOption.asset || 'N/A'}\`\n\n` +
        `⚠️ **Wallet not connected.** Please connect your wallet to proceed.\n\n` +
        `Once your wallet is connected, this agent will:\n` +
        `1. Create an EIP-3009 \`transferWithAuthorization\` signature request\n` +
        `2. Submit the signed payload to the x402 facilitator for settlement\n` +
        `3. Return the transaction hash for order confirmation\n\n` +
        `_Facilitator: ${FACILITATOR_URL}_`,
      mimeType: 'text/markdown',
    };

    yield {
      type: 'result',
      data: {
        paymentId,
        orderId: parsed.orderId,
        status: 'awaiting_wallet',
        paymentOption,
      },
    };
    return;
  }

  // Wallet is connected — proceed with payment flow
  const paymentId = `pay_${uuidv4().slice(0, 8)}`;
  createPaymentRecord(paymentId, paymentOption, parsed.orderId);

  yield { type: 'status', message: 'Wallet connected. Preparing payment...' };

  const networkInfo = SUPPORTED_NETWORKS[paymentOption.network];

  // In a full implementation, this would:
  // 1. Create an EIP-3009 transferWithAuthorization typed data request
  // 2. Send it to the user's wallet for signing
  // 3. Submit the signed payload to the facilitator's /settle endpoint
  // 4. Return the transaction hash
  //
  // For this demo, we simulate the flow and show what WOULD happen.

  yield { type: 'status', message: 'Creating payment authorization...' };

  // Simulate the EIP-3009 authorization structure
  const validBefore = Math.floor(Date.now() / 1000) + 900; // 15 minutes
  const nonce = `0x${uuidv4().replace(/-/g, '')}`;

  const authorization = {
    from: walletContext.address,
    to: paymentOption.payTo,
    value: paymentOption.price,
    validAfter: '0',
    validBefore: String(validBefore),
    nonce,
  };

  yield {
    type: 'status',
    message: 'Submitting payment to facilitator for settlement...',
  };

  // Simulate settlement (in production, this would call the facilitator)
  const mockTxHash = `0x${uuidv4().replace(/-/g, '')}${uuidv4().replace(/-/g, '').slice(0, 32)}`;

  updatePaymentRecord(paymentId, 'settled', mockTxHash);

  const receipt =
    `## ✅ Payment Settled\n\n` +
    `**Payment ID:** \`${paymentId}\`\n` +
    `**Order ID:** \`${parsed.orderId || 'N/A'}\`\n` +
    `**Amount:** ${paymentOption.price} USDC\n` +
    `**Network:** ${networkInfo?.name || paymentOption.network}\n` +
    `**From:** \`${walletContext.address}\`\n` +
    `**To:** \`${paymentOption.payTo}\`\n` +
    `**Transaction:** \`${mockTxHash}\`\n` +
    `**Status:** ✅ Settled\n` +
    `**Settled At:** ${new Date().toISOString()}\n\n` +
    `### Authorization Details\n` +
    `\`\`\`json\n${JSON.stringify(authorization, null, 2)}\n\`\`\`\n\n` +
    `_Facilitator: ${FACILITATOR_URL}_\n\n` +
    `### Next Step\n` +
    `Tell **@store**: "confirm order ${parsed.orderId} with tx ${mockTxHash}"`;

  yield {
    type: 'artifact',
    name: 'payment-receipt.md',
    content: receipt,
    mimeType: 'text/markdown',
  };

  yield {
    type: 'result',
    data: {
      paymentId,
      orderId: parsed.orderId,
      txHash: mockTxHash,
      status: 'settled',
      network: paymentOption.network,
      from: walletContext.address,
      to: paymentOption.payTo,
      amount: paymentOption.price,
    },
  };
}
